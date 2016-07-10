
; Copyright (c) 2006 by Roland Riegel <feedback@roland-riegel.de>

; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License version 2 as
; published by the Free Software Foundation.

.equ UBRRVAL = F_CPU/(BAUD*16)-1

uart_init:
        ; set baud rate
        ldi	genl, LOW(UBRRVAL)
        out_	UBRRL, genl
        ldi	genl, HIGH(UBRRVAL)
        out_	UBRRH, genl

        ; frame format: 8 bit, no parity, 1 bit
        ldi	genl, (1 << URSEL) | (1 << UCSZ1) | (1 << UCSZ0)
        out_	UCSRC, genl

        ; enable serial receiver and transmitter
        ldi	genl, (1 << RXEN) | (1 << TXEN)
        out_	UCSRB, genl

        ret

uart_xmtw:
        sbis_	UCSRA, UDRE
        rjmp	uart_xmtw	; wait until transmit buffer is empty
        out_	UDR, genh
uart_xmt:
        sbis_	UCSRA, UDRE
        rjmp	uart_xmt	; wait until transmit buffer is empty
        out_	UDR, genl
        ret
	
uart_send0:
	rcall	uart_xmt
uart_send:
        lpm_	genl, Z+
	tst	genl
	brne	uart_send0
	ret
	
uart_rec0:
        in_	genl, UDR
uart_rec:			; genl (out): byte received
        sbis_	UCSRA, RXC
        rjmp	uart_rec
	sbic_	UCSRA, FE
	rjmp	uart_rec0
        in_	genl, UDR
        ret

uart_recw:			;out: genh:genl
	rcall	uart_rec
	mov	genh, genl
	rjmp	uart_rec

uart_drain:
	movw	ZH:ZL, zeroh:zerol
        in_	genl, UDR
uart_drain_loop:
	sbic_	UCSRA, RXC
	rjmp	uart_drain
	adiw	ZH:ZL, 1
	brne	uart_drain_loop
	ret
