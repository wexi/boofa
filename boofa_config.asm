
; Copyright (c) 2006 by Roland Riegel <feedback@roland-riegel.de>

; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License version 2 as
; published by the Free Software Foundation.

.macro boofa_may_start_app
        ; start application if the bootloader
        ; push key is not pressed down
        cbi DDRD, 6
        sbic PIND, 6
        jmp 0
.endmacro

