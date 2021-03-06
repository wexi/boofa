
; Copyright (c) 2006 by Roland Riegel <feedback@roland-riegel.de>

; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License version 2 as
; published by the Free Software Foundation.

;; .listmac

#ifdef BIGFOOT
.equ DEVBOOT = LARGEBOOTSTART
#else
.equ DEVBOOT = FLASHEND ^ $1FF
#endif
.equ F_CPU = 16000000
.equ BAUD = 38400

; device specific boofa configuration
.equ DEVCODE = 0x44

; device specific register handling
.equ UBRRH = UBRR0H
.equ UBRRL = UBRR0L
.equ UDR = UDR0
.equ UCSRA = UCSR0A
.equ UCSRB = UCSR0B
.equ UCSRC = UCSR0C
.equ UCSRC_SELECT = 0
.equ UCSZ0 = UCSZ00
.equ UCSZ1 = UCSZ01
.equ RXEN = RXEN0
.equ TXEN = TXEN0
.equ UDRE = UDRE0
.equ RXC = RXC0
.equ FE = FE0

.def ZEROl = r2
.def ZEROh = r3
.def TEMPWl = r4		;W save
.def TEMPWh = r5
.def TEMPXl = r6		;X save
.def TEMPXh = r7
.def GENl = r16
.def GENh = r17
	
.def spad = r20			;for temporary macro use only

.def Wl = r24			;W is adiw/sbiw capable
.def Wh = r25
; X - AVR109 address pointer

.macro	ldiw
	ldi	@0L, LOW(@1)
	ldi	@0H, HIGH(@1)
.endmacro

.macro	subiw
	subi	@0L, LOW(@1)
	sbci	@0H, HIGH(@1)
.endmacro

.macro	addiw
	subiw	@0,$10000-@1
.endmacro

.macro	andiw
	andi	@0L, LOW(@1)
	andi	@0H, HIGH(@1)
.endmacro

.macro	cpiw
	ldi	spad, HIGH(@1)
	cpi	@0L, LOW(@1)
	cpc	@0H, spad
.endmacro	

.macro	tstw
	mov	spad, @0L
	or	spad, @0H
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
	sbi_	PORTB, 4	;input TP6 pulled high
	sbi_	DDRB, 5		;output TP5 low
	nop			;discharge time
	sbis_	PINB, 4		;skip if TP6 ≠ TP5
	rjmp	@0		;boot loader
	sbi_	DDRE, 5		;boot application
	sbi_	PORTE, 5	;RED LED ON
.endmacro
	
.macro	boofa			;indicate entering boofa
	sbi_	DDRB, 7
	sbi_	PORTB, 7	;GREEN LED ON
	sbi_	DDRD, 7		;CTS ON
.endmacro

.macro	boofa_led_on
	sbi_	PORTB, 7	;green led on
.endmacro

.macro	boofa_led_off
	cbi_	PORTB, 7	;green led off
.endmacro

.macro	boofa_prog_on
	sbi_	PORTE, 5	;red led on
.endmacro

.macro	boofa_prog_off
	cbi_	PORTE, 5	;red led off
.endmacro

.macro	boofa_prog_test
	sbis_	PORTE, 5
	rjmp	@0		;not in prog mode
.endmacro

.macro	xchg
	mov	spad,@0
	mov	@0,@1
	mov	@1,spad
.endmacro
