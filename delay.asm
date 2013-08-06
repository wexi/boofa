
; Copyright (c) 2006 by Roland Riegel <feedback@roland-riegel.de>

; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License version 2 as
; published by the Free Software Foundation.

        ; delay execution by a specified amount of time
delay_us: ; gen1 (in): delay in us
        push gen1

delay_us_loop:
        WAIT_1US
        
        dec gen1
        brne delay_us_loop

        pop gen1
        ret

        ; delay execution by a specified amount of time
delay_ms: ; gen1 (in): delay in ms
        push gen1
        push gen2
        push gen3

delay_ms_1000us:
        ldi gen2, LOW(1000)
        ldi gen3, HIGH(1000)
        
delay_ms_loop:
        WAIT_1US

        subi gen2, 1
        brcc delay_ms_loop
        subi gen3, 1
        brcc delay_ms_loop
        dec gen1
        brne delay_ms_1000us

        pop gen3
        pop gen2
        pop gen1
        ret

