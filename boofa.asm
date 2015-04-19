
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
        ldi	GENl, LOW(RAMEND)
        out_	SPL, GENl
        ldi	GENl, HIGH(RAMEND)
        out_	SPH, GENl
	
	rcall	uart_init
	rcall	uart_drain
	
boofa_restart:
	boot	boofa_exec
boofa_appl:
#ifndef	DEBUG
	movw	Zh:Zl, zeroh:zerol ;launch application if possible
	lpm	Yl, Z+
	lpm	Yh, Z+		;Y is first flash word
	adiw	Yh:Yl, 1
	breq	boofa_exec	;no code?
	jmp	0
#endif
boofa_exec:
	boofa

	movw	Xh:Xl, zeroh:zerol ;reset address pointer

boofa_loop:			;main loop
        rcall	uart_rec	;command char
	bst	GENl, 5		;T set on lower case char
	
        ; auto-increment status
boofa_cmd_a:
        cpi	GENl, 'a'
        brne	boofa_cmd_A_

        ldi	GENl, 'Y'
        rcall	uart_xmt

        rjmp	boofa_loop

        ; set address
boofa_cmd_A_:
        cpi	GENl, 'A'
        brne	boofa_cmd_e

        rcall	uart_recw
        movw	Xh:Xl, GENh:GENl

        ldi	GENl, CR
        rcall	uart_xmt

        rjmp	boofa_loop

        ; erase chip
boofa_cmd_e:
        cpi	GENl, 'e'
        brne	boofa_cmd_b
	boofa_prog_test	boofa_cmd_unknown

        rcall	flash_erase

        ldi	GENl, CR
        rcall	uart_xmt

        rjmp	boofa_loop

        ; block support
boofa_cmd_b:
        cpi	GENl, 'b'
        brne	boofa_cmd_B_

        ; we support block writing
        ldi	GENl, 'Y'
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
	ldi	GENh, 'B'
	cpse	GENl, GENh
	rjmp	boofa_cmd_g
	boofa_prog_test	boofa_cmd_unknown

        ; get block-size
        rcall	uart_recw
        movw	Wh:Wl, GENh:GENl
	subiw	gen, 1
	cpiw	gen, SRAM_SIZE/2
	brsh	boofa_fatal_error ;zero or more than buffer capacity???
	
        ; get type & data into SRAM
	movw	Yh:Yl, Wh:Wl
	ldiw	Z, SRAM_START
boofa_data:
	rcall	uart_rec
	st	Z+, GENl
	sbiw	Yh:Yl, 1
	brcc	boofa_data	;block-size+1 to account for F/E type

	ldiw	Y, SRAM_START
	ld	GENl, Y+
boofa_cmd_B_F:
        cpi	GENl, 'F'
        brne	boofa_cmd_B_E

	sbrc	Wl, 0
	rjmp	boofa_fatal_error ;odd byte count???

boofa_flash_pages:
	mov	GENh, Xh
	lsr	GENh
	cpi	GENh,DEVBOOT/512 ;boofa overwrite?
#ifdef	PANIC
	breq	boofa_fatal_error
#else
	in_	GENh, SREG	;set Z on overwrite
#endif
boofa_appl_code:
        movw	Zh:Zl, Xh:Xl
	andiw	Z, PAGESIZE-1
	lsl	Zl
	rol	Zh
boofa_flash_buffer:
	ld	r0, Y+
	ld	r1, Y+
#ifndef	PANIC
	sbrs	GENh, 1		;skip on boofa overlap
#endif
        rcall	flash_write_word
	sbiw	Wh:Wl, 2
	adiw	Xh:Xl, 1
	adiw	Zh:Zl, 2
	cpiw	Z, PAGESIZE << 1
	breq	boofa_flash_page
	tstw	W
	brne	boofa_flash_buffer
	
boofa_flash_page:
	sbiw	Xh:Xl, 1
        rcall	flash_set_addr
#ifndef	PANIC	
	sbrs	GENh, 1		;skip on boofa overlap
#endif
        rcall	flash_write_page
	adiw	Xh:Xl, 1
	tstw	W
	brne	boofa_flash_pages
	rjmp	boofa_cmd_B_common

boofa_cmd_B_E:
        cpi	GENl, 'E'
        brne	boofa_cmd_B_unknown

boofa_cmd_B_E_byte:
	rcall	eeprom_read
	mov	GENh,GENl
	ld	GENl, Y+
	cpse	GENl,GENh
        rcall	eeprom_write
	adiw	Xh:Xl, 1
	sbiw	Wh:Wl, 1
        brne	boofa_cmd_B_E_byte

boofa_cmd_B_common:
        ; answer
        ldi	GENl, CR
        rcall	uart_xmt
        rjmp	boofa_loop
boofa_cmd_B_unknown:
	rjmp	boofa_cmd_unknown

        ; start block read
boofa_cmd_g:
        cpi	GENl, 'g'
	breq	boofa_cmd_gee
	cpi	GENl, 'G'
        brne	boofa_cmd_R_

        ; get block size
boofa_cmd_gee:	
        rcall	uart_recw
        movw	Wh:Wl, GENh:GENl
	
	; for "G" if non-erased bytes are found
	movw	TEMPXh:TEMPXl, Xh:Xl 
	movw	TEMPWh:TEMPWl, Wh:Wl

        ; get data type
        rcall	uart_rec
boofa_cmd_g_F:
        cpi	GENl, 'F'
        brne	boofa_cmd_g_E

boofa_cmd_g_F_word:
        rcall	flash_read_word

	brts	boofa_cmd_ef1	;'g' ?
	cpiw	gen, $ffff	;'G'
	breq	boofa_cmd_ef2

	ldi	GENl, '0'	;non erased block mark
	rcall	uart_xmt
	movw	Xh:Xl, TEMPXh:TEMPXl
	movw	Wh:Wl, TEMPWh:TEMPWl
	set
	rjmp	boofa_cmd_g_F_word
	
boofa_cmd_ef1:
	rcall	uart_xmt
	mov	GENl, GENh
	rcall	uart_xmt

boofa_cmd_ef2:
	adiw	Xh:Xl, 1
	sbiw	Wh:Wl, 2
        brne	boofa_cmd_g_F_word
        rjmp	boofa_cmd_g_common

boofa_cmd_g_E:
        cpi	GENl, 'E'
        brne	boofa_cmd_g_unknown

boofa_cmd_g_E_byte:
        rcall	eeprom_read

	brts	boofa_cmd_ee1	;'g' ?
	cpi	GENl,$ff	;'G'
	breq	boofa_cmd_ee2

	ldi	GENl, '0'	;non erased block mark
	rcall	uart_xmt
	movw	Xh:Xl, TEMPXh:TEMPXl
	movw	Wh:Wl, TEMPWh:TEMPWl
	set
	rjmp	boofa_cmd_g_E_byte

boofa_cmd_ee1:
        rcall	uart_xmt

boofa_cmd_ee2:
	adiw	Xh:Xl, 1
	sbiw	Wh:Wl, 1
        brne	boofa_cmd_g_E_byte

boofa_cmd_g_common:
	brts	boofa_cmd_g_end
	ldi	GENl, '1'	;erased block mark
	rcall	uart_xmt
boofa_cmd_g_end:	
        rjmp	boofa_loop
boofa_cmd_g_unknown:
	rjmp	boofa_cmd_unknown

        ; read program memory
boofa_cmd_R_:
        cpi	GENl, 'R'
        brne	boofa_cmd_D_

        ; read a single word from flash
        rcall	flash_read_word
	adiw	Xh:Xl, 1

        ; send memory word
	xchg	GENl, GENh
        rcall	uart_xmt
	mov	GENl, GENh
	rcall	uart_xmt

        rjmp	boofa_loop

        ; write eeprom memory
boofa_cmd_D_:
        cpi	GENl, 'D'
        brne	boofa_cmd_d
	boofa_prog_test	boofa_cmd_unknown
        rcall	uart_rec
        rcall	eeprom_write
	adiw	Xh:Xl, 1
        rjmp	boofa_loop

        ; read eeprom memory
boofa_cmd_d:
        cpi	GENl, 'd'
        brne	boofa_cmd_l
        rcall	eeprom_read
        rcall	uart_xmt
	adiw	Xh:Xl, 1
        rjmp	boofa_loop

        ; write lockbits
boofa_cmd_l:
        cpi	GENl, 'l'
        brne	boofa_cmd_r
	boofa_prog_test	boofa_cmd_unknown

        rcall	uart_rec
        rcall	lock_write

        ldi	GENl, CR
        rcall	uart_xmt

        rjmp	boofa_loop

        ; read lockbits
boofa_cmd_r:
        cpi	GENl, 'r'
        brne	boofa_cmd_F_

        rcall	lock_read
        rcall	uart_xmt

        rjmp	boofa_loop

        ; read fuse bits
boofa_cmd_F_:
        cpi	GENl, 'F'
        brne	boofa_cmd_N_

        rcall	fuse_l_read
        rcall	uart_xmt

        rjmp	boofa_loop

        ; read high fuse bits
boofa_cmd_N_:
        cpi	GENl, 'N'
        brne	boofa_cmd_Q_

        rcall	fuse_h_read
        rcall	uart_xmt

        rjmp	boofa_loop

        ; read extended fuse bits
boofa_cmd_Q_:
        cpi	GENl, 'Q'
        brne	boofa_cmd_P_

        rcall	fuse_e_read
        rcall	uart_xmt

        rjmp	boofa_loop

        ; enter programming mode
boofa_cmd_P_:
        cpi	GENl, 'P'
        brne	boofa_cmd_L_

        ldi	GENl, CR
        rcall	uart_xmt
	boofa_prog_on
	
        rjmp	boofa_loop

        ; leave programming mode
boofa_cmd_L_:
        cpi	GENl, 'L'
        brne	boofa_cmd_E_

        ldi	GENl, CR
        rcall	uart_xmt
	boofa_prog_off

        rjmp	boofa_loop

        ; exit bootloader
boofa_cmd_E_:
        cpi	GENl, 'E'
        brne	boofa_cmd_p

        ldi	GENl, CR
        rcall	uart_xmt
	boofa_prog_off
	boofa_led_off

        rjmp	boofa_appl

        ; get programmer type
boofa_cmd_p:
        cpi	GENl, 'p'
        brne	boofa_cmd_t

        ; serial programmer
        ldi	GENl, 'S'
        rcall	uart_xmt

        rjmp	boofa_loop

        ; return supported device codes
boofa_cmd_t:
        cpi	GENl, 't'
        brne	boofa_cmd_x

        ; only the device we are running on
        ldi	GENl, DEVCODE
        rcall	uart_xmt
        ; send list terminator
        ldi	GENl, 0
        rcall	uart_xmt

        rjmp	boofa_loop

        ; set led
boofa_cmd_x:
        cpi	GENl, 'x'
        brne	boofa_cmd_y

        rcall	uart_rec

        ldi	GENl, CR
        rcall	uart_xmt

	boofa_led_on
        rjmp	boofa_loop

        ; clear led
boofa_cmd_y:
        cpi	GENl, 'y'
        brne	boofa_cmd_T_

        rcall	uart_rec

        ldi	GENl, CR
        rcall	uart_xmt

	boofa_led_off
        rjmp	boofa_loop

        ; set device type
boofa_cmd_T_:
        cpi	GENl, 'T'
        brne	boofa_cmd_S_

        rcall	uart_rec
        cpi	GENl, DEVCODE
        brne	boofa_cmd_unknown

        ldi	GENl, CR
        rcall	uart_xmt

        rjmp	boofa_loop

        ; return programmer identifier
boofa_cmd_S_:
        cpi	GENl, 'S'
        brne	boofa_cmd_V_

	ldz	boofa_ident
	rcall	uart_send
        rjmp	boofa_loop
boofa_ident:
.db	"AVRBOOT",0

        ; return software version
boofa_cmd_V_:
        cpi	GENl, 'V'
        brne	boofa_cmd_s

        ldi	GENl, '0'
        rcall	uart_xmt
        ldi	GENl, '4'
        rcall	uart_xmt

        rjmp	boofa_loop

        ; return signature bytes
boofa_cmd_s:
        cpi	GENl, 's'
        brne	boofa_cmd_z

        ldi	GENl, SIGNATURE_002
        rcall	uart_xmt
        ldi	GENl, SIGNATURE_001
        rcall	uart_xmt
        ldi	GENl, SIGNATURE_000
        rcall	uart_xmt

        rjmp	boofa_loop

	; extension: report address 
boofa_cmd_z:
	cpi	GENl, 'z'
	brne	boofa_cmd_oem
	
	movw	GENh:GENl, Xh:Xl
	rcall	uart_xmtw

	rjmp	boofa_loop

boofa_cmd_oem:	
	cpi	GENl, 'Z'
	brne	boofa_cmd_ESC
	ldz	oem_string
	rcall	uart_send
        rjmp	boofa_loop
        ; sync
boofa_cmd_ESC:
        cpi	GENl, 0x1b
        brne	boofa_cmd_unknown

        rjmp	boofa_loop

        ; unknown commands
boofa_cmd_unknown:
	rcall	uart_drain
        ldi	GENl, '?'
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
