
; Copyright (c) 2006 by Roland Riegel <feedback@roland-riegel.de>

; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License version 2 as
; published by the Free Software Foundation.

bits_read: ; gen1 (in): fuse or lock identifier
           ; gen1 (out): requested fuse or lock bits
        mov	ZL, gen1
        clr	ZH

        ldi	gen1, (1 << BLBSET) | (1 << SPMEN)
        out_	SPMCSR, gen1
        lpm	gen1, Z
        ret

bits_write: ; gen1 (in): fuse or lock identifier
            ; r0 (in): fuse or lock bits to write
        mov	ZL, gen1
        clr	ZH

        ldi	gen1, (1 << BLBSET) | (1 << SPMEN)
        out_	SPMCSR, gen1
        rjmp	spm_do

