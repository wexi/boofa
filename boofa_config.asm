
; Copyright (c) 2006 by Roland Riegel <feedback@roland-riegel.de>

; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License version 2 as
; published by the Free Software Foundation.

; .listmac

#ifdef	BIGFOOT
.equ DEVBOOT = LARGEBOOTSTART
#else
.equ DEVBOOT = FLASHEND ^ $1FF
#endif

.equ F_CPU = 7372800
.equ BAUD = 38400

; AVR109 device type:
.equ DEVCODE = 0x44

; USART selection:
.equ UBRRH = UBRR1H
.equ UBRRL = UBRR1L
.equ UDR = UDR1
.equ UCSRA = UCSR1A
.equ UCSRB = UCSR1B
.equ UCSRC = UCSR1C
	
.equ URSEL = URSEL1
.equ UCSZ0 = UCSZ10
.equ UCSZ1 = UCSZ11
.equ RXEN = RXEN1
.equ TXEN = TXEN1
.equ UDRE = UDRE1
.equ RXC = RXC1
.equ FE = FE1
	
.def zerol = r2
.def zeroh = r3
.def tempwl = r4		;W save
.def tempwh = r5
.def tempxl = r6		;X save
.def tempxh = r7
.def genl = r16
.def genh = r17
	
.def spad = r20			;for temporary macro use only

.def wl = r24			;W is adiw/sbiw capable
.def wh = r25
; X - AVR109 address pointer

.macro	ldiw
	ldi	@0l, low(@1)
	ldi	@0h, high(@1)
.endmacro

.macro	subiw
	subi	@0l, low(@1)
	sbci	@0h, high(@1)
.endmacro

.macro	addiw
	subiw	@0,$10000-@1
.endmacro

.macro	andiw
	andi	@0l, low(@1)
	andi	@0h, high(@1)
.endmacro

.macro	cpiw
	ldi	spad, high(@1)
	cpi	@0l, low(@1)
	cpc	@0h, spad
.endmacro	

.macro	tstw
	mov	spad, @0l
	or	spad, @0h
.endmacro
	
.macro	in_
.if (@1) < 64
	in	@0, @1
.else
	lds	@0, @1
.endif
.endmacro

.macro	out_
.if (@0) < 64
	out	@0, @1
.else
	sts	@0, @1
.endif
.endmacro

.macro	sbi_
.if (@0) < 32
	sbi	@0, @1
.else
	in_	spad, @0
	sbr	spad, 1 << @1
	out_	@0, spad 
.endif
.endmacro

.macro	cbi_
.if (@0) < 32
	cbi	@0, @1
.else
	in_	spad, @0
	cbr	spad, 1 << @1
	out_	@0, spad 
.endif
.endmacro

.macro	sbis_
.if (@0) < 32
	sbis	@0, @1
.else
	in_	spad, @0
	sbrs	spad, @1
.endif
.endmacro

.macro	sbic_
.if (@0) < 32
	sbic	@0, @1
.else
	in_	spad, @0
	sbrc	spad, @1
.endif
.endmacro

.macro	lpm_
.if FLASHEND < 0x8000
        lpm	@0, @1
.else
        elpm	@0, @1
.endif
.endmacro

.macro	ldz			;@0 is word address
.if	FLASHEND >= 0x8000
	ldi	ZL, (@0 >> 15) & 255
	out_	RAMPZ, ZL
.endif	
	ldi	ZL, (@0 << 1) & 255
	ldi	ZH, (@0 >> 7) & 255
.endmacro

.equ	CR = 0x0d
.equ	LF = 0x0a

.macro	boot			;to boot (continue) or to boofa (rjmp)
	sbic_	PINB, 0		;skip if the CTS is ON
	rjmp	@0		;boot loader
.endmacro
	
.macro	boofa			;indicate entering boofa
	sbi_	DDRD, 3
	sbi_	PORTD, 3	;LED ON
	sbi_	DDRB, 1		;RTS ON
.endmacro

.macro	boofa_led_on
.endmacro

.macro	boofa_led_off
.endmacro

.macro	boofa_prog_on
	cbi_	PORTD, 3	;red led off
.endmacro

.macro	boofa_prog_off
	sbi_	PORTD, 3	;red led on
.endmacro

.macro	boofa_prog_test
	sbic_	PORTD, 3
	rjmp	@0		;not in prog mode
.endmacro

.macro	xchg
	mov	spad,@0
	mov	@0,@1
	mov	@1,spad
.endmacro
