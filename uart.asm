
; Copyright (c) 2006 by Roland Riegel <feedback@roland-riegel.de>

; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License version 2 as
; published by the Free Software Foundation.

.equ UBRRVAL = F_CPU/(BAUD*16)-1

uart_init:
        ; set baud rate
        ldi	gen1, LOW(UBRRVAL)
        out_	UBRRL, gen1
        ldi	gen1, HIGH(UBRRVAL)
        out_	UBRRH, gen1

        ; frame format: 8 bit, no parity, 1 bit
        ldi	gen1, UCSRC_SELECT | (1 << UCSZ1) | (1 << UCSZ0)
        out_	UCSRC, gen1

        ; enable serial receiver and transmitter
        ldi	gen1, (1 << RXEN) | (1 << TXEN)
        out_	UCSRB, gen1

        ret

uart_xmt:
        sbis_	UCSRA, UDRE
        rjmp	uart_xmt	; wait until transmit buffer is empty
        out_	UDR, gen1
        ret
	
uart_send0:
	rcall	uart_xmt
uart_send:
        lpm_	gen1, Z+
	tst	gen1
	brne	uart_send0
	ret
	
uart_rec0:
        in_	gen1, UDR
uart_rec:			; gen1 (out): byte received
        sbis_	UCSRA, RXC
        rjmp	uart_rec
	sbic_	UCSRA, FE
	rjmp	uart_rec0
        in_	gen1, UDR
        ret
