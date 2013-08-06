
; Copyright (c) 2006 by Roland Riegel <feedback@roland-riegel.de>

; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License version 2 as
; published by the Free Software Foundation.

uart_init:
        push gen1

        ; set baud rate
        ldi gen1, LOW(UBRRVAL)
        out UBRRL, gen1
        ldi gen1, HIGH(UBRRVAL)
.if UBRRH > 0x3f
        sts UBRRH, gen1
.else
        out UBRRH, gen1
.endif

        ; frame format: 8 bit, no parity, 1 bit
        ldi gen1, UCSRC_SELECT | (1 << UCSZ1) | (1 << UCSZ0)
.if UCSRC > 0x3f
        sts UCSRC, gen1
.else
        out UCSRC, gen1
.endif

        ; enable serial receiver and transmitter
        ldi gen1, (1 << RXEN) | (1 << TXEN)
        out UCSRB, gen1

        pop gen1
        ret

uart_send:
        ; wait until transmit buffer is empty
        sbis UCSRA, UDRE
        rjmp uart_send

        out UDR, gen1
        ret

uart_send_hex:
        push gen1
        push gen2

        mov gen2, gen1
        andi gen2, 0x0f ; lower nibble in gen2

        swap gen1
        andi gen1, 0x0f ; upper nibble in gen1

        subi gen2, -'0' ; add '0'
        cpi gen2, '9' + 1
        brlo uart_send_hex_lower_ok
        subi gen2, -7 ; add 7 to reach 'A'-'F'
uart_send_hex_lower_ok:

        subi gen1, -'0' ; add '0'
        cpi gen1, '9' + 1
        brlo uart_send_hex_upper_ok
        subi gen1, -7 ; add 7 to reach 'A'-'F'
uart_send_hex_upper_ok:

        rcall uart_send
        mov gen1, gen2
        rcall uart_send

        pop gen2
        pop gen1
        ret

        ; receives a byte
uart_rec: ; gen1 (out): byte received
        ; check receive buffer
        sbis UCSRA, RXC
        rjmp uart_rec

        in gen1, UDR

        ret

