
; Copyright (c) 2006 by Roland Riegel <feedback@roland-riegel.de>

; This program is free software; you can redistribute it and/or	modify
; it under the terms of the GNU General Public License version 2 as
; published by the Free Software Foundation.

lock_read: ; genl (out): lock bits
        ldi	genl, 0x01
        rjmp	bits_read

lock_write: ; genl (in): lock bits to write
        mov	r0, genl
        ldi	genl, 0xc3
        or	r0, genl
        ldi	genl, 0x01
        rjmp	bits_write

