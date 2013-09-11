
; boofa - the BOOtloader For	Avr microcontrollers
; Copyright (c) 2006 by Roland Riegel <feedback@roland-riegel.de>

; This program is free software; you can redistribute it and/or	modify
; it under the terms of the GNU General Public License version 2 as
; published by the Free Software Foundation.

.include "boofa_config.asm"

; put boot loader into boot section
.org	DEVBOOT
boofa_start:
	clr	zerol
	clr	zeroh
        ldi	genl, LOW(RAMEND)
        out_	SPL, genl
        ldi	genl, HIGH(RAMEND)
        out_	SPH, genl
	
	rcall	uart_init
	rcall	uart_drain
	
boofa_restart:
	boot	boofa_load
boofa_appl:
#ifndef	DEBUG
	movw	ZH:ZL, zeroh:zerol ;launch application if possible
	lpm	YL, Z+
	lpm	YH, Z+		;Y is first flash word
	adiw	YH:YL, 1
	breq	boofa_load	;no code?
	jmp	0
#endif
boofa_load:
	boofa

	movw	XH:XL, zeroh:zerol ;reset address pointer

boofa_loop:			; main loop
        rcall	uart_rec
	
        ; auto-increment status
boofa_cmd_a:
        cpi	genl, 'a'
        brne	boofa_cmd_A_

        ldi	genl, 'Y'
        rcall	uart_xmt

        rjmp	boofa_loop

        ; set address
boofa_cmd_A_:
        cpi	genl, 'A'
        brne	boofa_cmd_e

        rcall	uart_recw
        movw	XH:XL, genh:genl

        ldi	genl, CR
        rcall	uart_xmt

        rjmp	boofa_loop

        ; erase chip
boofa_cmd_e:
        cpi	genl, 'e'
        brne	boofa_cmd_b
	boofa_prog_test	boofa_cmd_unknown

        rcall	flash_erase

        ldi	genl, CR
        rcall	uart_xmt

        rjmp	boofa_loop

        ; block support
boofa_cmd_b:
        cpi	genl, 'b'
        brne	boofa_cmd_B_

        ; we support block writing
        ldi	genl, 'Y'
        rcall	uart_xmt

        ; return buffer-size in bytes
	ldiw	gen, SRAM_SIZE/2	;largest available power of two
        rcall	uart_xmtw

        rjmp	boofa_loop

boofa_fatal_error:
	boofa_prog_off
	rjmp	boofa_cmd_unknown	

        ; start block load
boofa_cmd_B_:
	ldi	genh, 'B'
	cpse	genl, genh
	rjmp	boofa_cmd_g
	boofa_prog_test	boofa_cmd_unknown

        ; get block-size
        rcall	uart_recw
        movw	WH:WL, genh:genl
	subiw	gen, 1
	cpiw	gen, SRAM_SIZE/2
	brsh	boofa_fatal_error ;zero or more than buffer capacity???
	
        ; get type & data into SRAM
	movw	YH:YL, WH:WL
	ldiw	Z, SRAM_START
boofa_data:
	rcall	uart_rec
	st	Z+, genl
	sbiw	YH:YL, 1
	brcc	boofa_data	;block-size+1 to account for F/E type

	ldiw	Y, SRAM_START
	ld	genl, Y+
boofa_cmd_B_F:
        cpi	genl, 'F'
        brne	boofa_cmd_B_E

	sbrc	WL, 0
	rjmp	boofa_fatal_error ;odd byte count???

boofa_flash_pages:
	mov	genh, XH
	lsr	genh
	cpi	genh,DEVBOOT/512
	breq	boofa_fatal_error ;overwrite boofa???
boofa_appl_code:
        movw	ZH:ZL, XH:XL
	andiw	Z, PAGESIZE-1
	lsl	ZL
	rol	ZH
boofa_flash_buffer:
	ld	r0, Y+
	ld	r1, Y+
        rcall	flash_write_word
	sbiw	WH:WL, 2
	adiw	XH:XL, 1
	adiw	ZH:ZL, 2
	cpiw	Z, PAGESIZE << 1
	breq	boofa_flash_page
	tstw	W
	brne	boofa_flash_buffer
	
boofa_flash_page:
	sbiw	XH:XL, 1
        rcall	flash_set_addr
        rcall	flash_write_page
	adiw	XH:XL, 1
	tstw	W
	brne	boofa_flash_pages
	rjmp	boofa_cmd_B_common

boofa_cmd_B_E:
        cpi	genl, 'E'
        brne	boofa_cmd_B_unknown

boofa_cmd_B_E_byte:
	ld	genl, Y+
        rcall	eeprom_write
	adiw	XH:XL, 1
	sbiw	WH:WL, 1
        brne	boofa_cmd_B_E_byte

boofa_cmd_B_common:
        ; answer
        ldi	genl, CR
        rcall	uart_xmt
        rjmp	boofa_loop
boofa_cmd_B_unknown:
	rjmp	boofa_cmd_unknown

        ; start block read
boofa_cmd_g:
        cpi	genl, 'g'
        brne	boofa_cmd_R_

        ; get block size
        rcall	uart_recw
        movw	WH:WL, genh:genl

        ; get data type
        rcall	uart_rec
boofa_cmd_g_F:
        cpi	genl, 'F'
        brne	boofa_cmd_g_E

boofa_cmd_g_F_word:
        rcall	flash_read_word

	rcall	uart_xmt
	mov	genl, genh
	rcall	uart_xmt
	
	adiw	XH:XL, 1
	sbiw	WH:WL, 2
        brne	boofa_cmd_g_F_word

        rjmp	boofa_cmd_g_common

boofa_cmd_g_E:
        cpi	genl, 'E'
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
        cpi	genl, 'R'
        brne	boofa_cmd_D_

        ; read a single word from flash
        rcall	flash_read_word
	adiw	XH:XL, 1

        ; send memory word
	xchg	genl, genh
        rcall	uart_xmt
	mov	genl, genh
	rcall	uart_xmt

        rjmp	boofa_loop

        ; write eeprom memory
boofa_cmd_D_:
        cpi	genl, 'D'
        brne	boofa_cmd_d
	boofa_prog_test	boofa_cmd_unknown
        rcall	uart_rec
        rcall	eeprom_write
	adiw	XH:XL, 1
        rjmp	boofa_loop

        ; read eeprom memory
boofa_cmd_d:
        cpi	genl, 'd'
        brne	boofa_cmd_l
        rcall	eeprom_read
        rcall	uart_xmt
	adiw	XH:XL, 1
        rjmp	boofa_loop

        ; write lockbits
boofa_cmd_l:
        cpi	genl, 'l'
        brne	boofa_cmd_r
	boofa_prog_test	boofa_cmd_unknown

        rcall	uart_rec
        rcall	lock_write

        ldi	genl, CR
        rcall	uart_xmt

        rjmp	boofa_loop

        ; read lockbits
boofa_cmd_r:
        cpi	genl, 'r'
        brne	boofa_cmd_F_

        rcall	lock_read
        rcall	uart_xmt

        rjmp	boofa_loop

        ; read fuse bits
boofa_cmd_F_:
        cpi	genl, 'F'
        brne	boofa_cmd_N_

        rcall	fuse_l_read
        rcall	uart_xmt

        rjmp	boofa_loop

        ; read high fuse bits
boofa_cmd_N_:
        cpi	genl, 'N'
        brne	boofa_cmd_Q_

        rcall	fuse_h_read
        rcall	uart_xmt

        rjmp	boofa_loop

        ; read extended fuse bits
boofa_cmd_Q_:
        cpi	genl, 'Q'
        brne	boofa_cmd_P_

        rcall	fuse_e_read
        rcall	uart_xmt

        rjmp	boofa_loop

        ; enter programming mode
boofa_cmd_P_:
        cpi	genl, 'P'
        brne	boofa_cmd_L_

        ldi	genl, CR
        rcall	uart_xmt
	boofa_prog_on
	
        rjmp	boofa_loop

        ; leave programming mode
boofa_cmd_L_:
        cpi	genl, 'L'
        brne	boofa_cmd_E_

        ldi	genl, CR
        rcall	uart_xmt
	boofa_prog_off

        rjmp	boofa_loop

        ; exit bootloader
boofa_cmd_E_:
        cpi	genl, 'E'
        brne	boofa_cmd_p

        ldi	genl, CR
        rcall	uart_xmt
	boofa_prog_off
	boofa_led_off

        rjmp	boofa_restart

        ; get programmer type
boofa_cmd_p:
        cpi	genl, 'p'
        brne	boofa_cmd_t

        ; serial programmer
        ldi	genl, 'S'
        rcall	uart_xmt

        rjmp	boofa_loop

        ; return supported device codes
boofa_cmd_t:
        cpi	genl, 't'
        brne	boofa_cmd_x

        ; only the device we are running on
        ldi	genl, DEVCODE
        rcall	uart_xmt
        ; send list terminator
        ldi	genl, 0
        rcall	uart_xmt

        rjmp	boofa_loop

        ; set led
boofa_cmd_x:
        cpi	genl, 'x'
        brne	boofa_cmd_y

        rcall	uart_rec

        ldi	genl, CR
        rcall	uart_xmt

	boofa_led_on
        rjmp	boofa_loop

        ; clear led
boofa_cmd_y:
        cpi	genl, 'y'
        brne	boofa_cmd_T_

        rcall	uart_rec

        ldi	genl, CR
        rcall	uart_xmt

	boofa_led_off
        rjmp	boofa_loop

        ; set device type
boofa_cmd_T_:
        cpi	genl, 'T'
        brne	boofa_cmd_S_

        rcall	uart_rec
        cpi	genl, DEVCODE
        brne	boofa_cmd_unknown

        ldi	genl, CR
        rcall	uart_xmt

        rjmp	boofa_loop

        ; return programmer identifier
boofa_cmd_S_:
        cpi	genl, 'S'
        brne	boofa_cmd_V_

	ldz	boofa_ident
	rcall	uart_send
        rjmp	boofa_loop
boofa_ident:
.db	"AVRBOOT",0

        ; return software version
boofa_cmd_V_:
        cpi	genl, 'V'
        brne	boofa_cmd_s

        ldi	genl, '0'
        rcall	uart_xmt
        ldi	genl, '1'
        rcall	uart_xmt

        rjmp	boofa_loop

        ; return signature bytes
boofa_cmd_s:
        cpi	genl, 's'
        brne	boofa_cmd_z

        ldi	genl, SIGNATURE_002
        rcall	uart_xmt
        ldi	genl, SIGNATURE_001
        rcall	uart_xmt
        ldi	genl, SIGNATURE_000
        rcall	uart_xmt

        rjmp	boofa_loop

	; extension: report address 
boofa_cmd_z:
	cpi	genl, 'z'
	brne	boofa_cmd_oem
	
	movw	genh:genl, XH:XL
	rcall	uart_xmtw

	rjmp	boofa_loop

boofa_cmd_oem:	
	cpi	genl, 'Z'
	brne	boofa_cmd_ESC
	ldz	oem_string
	rcall	uart_send
        rjmp	boofa_loop
        ; sync
boofa_cmd_ESC:
        cpi	genl, 0x1b
        brne	boofa_cmd_unknown

        rjmp	boofa_loop

        ; unknown commands
boofa_cmd_unknown:
	rcall	uart_drain
        ldi	genl, '?'
        rcall	uart_xmt
	
        rjmp	boofa_loop

.include "bits.asm"
.include "eeprom.asm"
.include "flash.asm"
.include "fuse.asm"
.include "lock.asm"
.include "spm.asm"
.include "uart.asm"
	
oem_string:
#ifdef	OEM
.include "oem.asm"
#else
 .db	"https://github.com/wexi/boofa", CR, LF, 0
#endif

boofa_end:
.if	(boofa_end - boofa_start) > 512
	.error	"BOOFA SIZE EXCEEDS 512 WORDS"	
.endif
