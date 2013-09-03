
; boofa - the BOOtloader For	Avr microcontrollers
; Copyright (c) 2006 by Roland Riegel <feedback@roland-riegel.de>

; This program is free software; you can redistribute it and/or	modify
; it under the terms of the GNU General Public License version 2 as
; published by the Free Software Foundation.

.include "boofa_config.asm"

; put boot loader into boot section
.org	DEVBOOT
	clr	zerol		;always
	clr	zeroh		; zero
	
	boot	boofa_load
	
boofa_appl:
.ifndef	DEBUG
	movw	ZH:ZL, zeroh:zerol ;launch application if possible
	lpm	YL, Z+
	lpm	YH, Z+		;Y is first flash word
	adiw	YH:YL, 1
	breq	boofa_load	;no code?
	jmp	0
.endif
boofa_load:
	boofa

        ldi	gen1, LOW(RAMEND)
        out_	SPL, gen1
        ldi	gen1, HIGH(RAMEND)
        out_	SPH, gen1
	movw	XH:XL, zeroh:zerol ;reset address pointer
	rcall	uart_init

boofa_loop:			; main loop
        rcall	uart_rec
	
        ; auto-increment status
boofa_cmd_a:
        cpi	gen1, 'a'
        brne	boofa_cmd_A_

        ldi	gen1, 'Y'
        rcall	uart_xmt

        rjmp	boofa_loop

        ; set address
boofa_cmd_A_:
        cpi	gen1, 'A'
        brne	boofa_cmd_e

        rcall	uart_rec
        mov	XH, gen1
        rcall	uart_rec
        mov	XL, gen1

        ldi	gen1, CR
        rcall	uart_xmt

        rjmp	boofa_loop

        ; erase chip
boofa_cmd_e:
        cpi	gen1, 'e'
        brne	boofa_cmd_b
	boofa_prog_test	boofa_cmd_unknown

        rcall	flash_erase

        ldi	gen1, CR
        rcall	uart_xmt

        rjmp	boofa_loop

        ; block support
boofa_cmd_b:
        cpi	gen1, 'b'
        brne	boofa_cmd_B_

        ; we support block writing
        ldi	gen1, 'Y'
        rcall	uart_xmt

        ; return blocksize in bytes
        ldi	gen1, HIGH(PAGESIZE << 1)
        rcall	uart_xmt
        ldi	gen1, LOW(PAGESIZE << 1)
        rcall	uart_xmt

        rjmp	boofa_loop

        ; start block load
boofa_cmd_B_:
        cpi	gen1, 'B'
        brne	boofa_cmd_g
	boofa_prog_test	boofa_cmd_unknown

        ; get block size
        rcall	uart_rec
        mov	WH, gen1
        rcall	uart_rec
        mov	WL, gen1
	
        ; get data type
        rcall	uart_rec

boofa_cmd_B_F:
        cpi	gen1, 'F'
        brne	boofa_cmd_B_E

	cpi	WL, LOW(PAGESIZE << 1)
	brne	boofa_cmd_B_unknown
        cpi	WH, HIGH(PAGESIZE << 1)
	brne	boofa_cmd_B_unknown

	movw	YH:YL, XH:XL
        movw	ZH:ZL, zeroh:zerol

boofa_cmd_B_F_word:
	rcall	uart_rec
	mov	r0, gen1
	rcall	uart_rec
	xchg	r1, gen1
	
        rcall	flash_write_word
	adiw	ZH:ZL, 2
	adiw	YH:YL, 1
	sbiw	WH:WL, 2
        brne	boofa_cmd_B_F_word
	
        rcall	flash_set_addr
        rcall	flash_write_page
	movw	XH:XL, YH:YL

        rjmp	boofa_cmd_B_common

boofa_cmd_B_E:
        cpi	gen1, 'E'
        brne	boofa_cmd_B_unknown

boofa_cmd_B_E_byte:
        rcall	uart_rec
        rcall	eeprom_write
	adiw	XH:XL, 1
	sbiw	WH:WL, 1
        brne	boofa_cmd_B_E_byte

boofa_cmd_B_common:
        ; answer
        ldi	gen1, CR
        rcall	uart_xmt
        rjmp	boofa_loop
boofa_cmd_B_unknown:
	rjmp	boofa_cmd_unknown

        ; start block read
boofa_cmd_g:
        cpi	gen1, 'g'
        brne	boofa_cmd_R_

        ; get block size
        rcall	uart_rec
        mov	WH, gen1
        rcall	uart_rec
        mov	WL, gen1

        ; get data type
        rcall	uart_rec
boofa_cmd_g_F:
        cpi	gen1, 'F'
        brne	boofa_cmd_g_E

boofa_cmd_g_F_word:
        rcall	flash_read_word

	rcall	uart_xmt
	mov	gen1, gen2
	rcall	uart_xmt
	
	adiw	XH:XL, 1
	sbiw	WH:WL, 2
        brne	boofa_cmd_g_F_word

        rjmp	boofa_cmd_g_common

boofa_cmd_g_E:
        cpi	gen1, 'E'
        brne	boofa_cmd_g_unknown

boofa_cmd_g_E_byte:
        rcall	eeprom_read
        rcall	uart_xmt
	adiw	XH:XL, 1
	sbiw	WH:WL, 1
        brne	boofa_cmd_g_E_byte

boofa_cmd_g_common:
        rjmp	boofa_loop
boofa_cmd_g_unknown:
	rjmp	boofa_cmd_unknown

        ; read program memory
boofa_cmd_R_:
        cpi	gen1, 'R'
        brne	boofa_cmd_D_

        ; read a single word from flash
        rcall	flash_read_word
	adiw	XH:XL, 1

        ; send memory word
	xchg	gen1, gen2
        rcall	uart_xmt
	mov	gen1, gen2
	rcall	uart_xmt

        rjmp	boofa_loop

        ; write eeprom memory
boofa_cmd_D_:
        cpi	gen1, 'D'
        brne	boofa_cmd_d
	boofa_prog_test	boofa_cmd_unknown
        rcall	uart_rec
        rcall	eeprom_write
	adiw	XH:XL, 1
        rjmp	boofa_loop

        ; read eeprom memory
boofa_cmd_d:
        cpi	gen1, 'd'
        brne	boofa_cmd_l
        rcall	eeprom_read
        rcall	uart_xmt
	adiw	XH:XL, 1
        rjmp	boofa_loop

        ; write lockbits
boofa_cmd_l:
        cpi	gen1, 'l'
        brne	boofa_cmd_r
	boofa_prog_test	boofa_cmd_unknown

        rcall	uart_rec
        rcall	lock_write

        ldi	gen1, CR
        rcall	uart_xmt

        rjmp	boofa_loop

        ; read lockbits
boofa_cmd_r:
        cpi	gen1, 'r'
        brne	boofa_cmd_F_

        rcall	lock_read
        rcall	uart_xmt

        rjmp	boofa_loop

        ; read fuse bits
boofa_cmd_F_:
        cpi	gen1, 'F'
        brne	boofa_cmd_N_

        rcall	fuse_l_read
        rcall	uart_xmt

        rjmp	boofa_loop

        ; read high fuse bits
boofa_cmd_N_:
        cpi	gen1, 'N'
        brne	boofa_cmd_Q_

        rcall	fuse_h_read
        rcall	uart_xmt

        rjmp	boofa_loop

        ; read extended fuse bits
boofa_cmd_Q_:
        cpi	gen1, 'Q'
        brne	boofa_cmd_P_

        rcall	fuse_e_read
        rcall	uart_xmt

        rjmp	boofa_loop

        ; enter programming mode
boofa_cmd_P_:
        cpi	gen1, 'P'
        brne	boofa_cmd_L_

        ldi	gen1, CR
        rcall	uart_xmt
	boofa_prog_on
	
        rjmp	boofa_loop

        ; leave programming mode
boofa_cmd_L_:
        cpi	gen1, 'L'
        brne	boofa_cmd_E_

        ldi	gen1, CR
        rcall	uart_xmt
	boofa_prog_off

        rjmp	boofa_loop

        ; exit bootloader
boofa_cmd_E_:
        cpi	gen1, 'E'
        brne	boofa_cmd_p

        ldi	gen1, CR
        rcall	uart_xmt
	boofa_prog_off
	boofa_led_off

        rjmp	boofa_appl

        ; get programmer type
boofa_cmd_p:
        cpi	gen1, 'p'
        brne	boofa_cmd_t

        ; serial programmer
        ldi	gen1, 'S'
        rcall	uart_xmt

        rjmp	boofa_loop

        ; return supported device codes
boofa_cmd_t:
        cpi	gen1, 't'
        brne	boofa_cmd_x

        ; only the device we are running on
        ldi	gen1, DEVCODE
        rcall	uart_xmt
        ; send list terminator
        ldi	gen1, 0
        rcall	uart_xmt

        rjmp	boofa_loop

        ; set led
boofa_cmd_x:
        cpi	gen1, 'x'
        brne	boofa_cmd_y

        rcall	uart_rec

        ldi	gen1, CR
        rcall	uart_xmt

	boofa_led_on
        rjmp	boofa_loop

        ; clear led
boofa_cmd_y:
        cpi	gen1, 'y'
        brne	boofa_cmd_T_

        rcall	uart_rec

        ldi	gen1, CR
        rcall	uart_xmt

	boofa_led_off
        rjmp	boofa_loop

        ; set device type
boofa_cmd_T_:
        cpi	gen1, 'T'
        brne	boofa_cmd_S_

        rcall	uart_rec
        cpi	gen1, DEVCODE
        brne	boofa_cmd_unknown

        ldi	gen1, CR
        rcall	uart_xmt

        rjmp	boofa_loop

        ; return programmer identifier
boofa_cmd_S_:
        cpi	gen1, 'S'
        brne	boofa_cmd_V_

	ldz	boofa_ident
	rcall	uart_send
        rjmp	boofa_loop
boofa_ident:
.db	"AVRBOOT",0

        ; return software version
boofa_cmd_V_:
        cpi	gen1, 'V'
        brne	boofa_cmd_s

        ldi	gen1, '0'
        rcall	uart_xmt
        ldi	gen1, '1'
        rcall	uart_xmt

        rjmp	boofa_loop

        ; return signature bytes
boofa_cmd_s:
        cpi	gen1, 's'
        brne	boofa_cmd_ESC

        ldi	gen1, SIGNATURE_002
        rcall	uart_xmt
        ldi	gen1, SIGNATURE_001
        rcall	uart_xmt
        ldi	gen1, SIGNATURE_000
        rcall	uart_xmt

        rjmp	boofa_loop

        ; sync
boofa_cmd_ESC:
        cpi	gen1, 0x1b
        brne	boofa_cmd_unknown

        rjmp	boofa_loop

        ; unknown commands
boofa_cmd_unknown:
        ldi	gen1, '?'
        rcall	uart_xmt
        rjmp	boofa_loop

.include "bits.asm"
.include "eeprom.asm"
.include "flash.asm"
.include "fuse.asm"
.include "lock.asm"
.include "spm.asm"
.include "uart.asm"

