
; Copyright (c) 2006 by Roland Riegel <feedback@roland-riegel.de>

; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License version 2 as
; published by the Free Software Foundation.

bits_read: ; genl (in): fuse or lock identifier
           ; genl (out): requested fuse or lock bits
        mov	ZL, genl
        clr	ZH

        ldi	genl, (1 << BLBSET) | (1 << SPMEN)
        out_	SPMCR, genl
        lpm	genl, Z
        ret

bits_write: ; genl (in): fuse or lock identifier
            ; r0 (in): fuse or lock bits to write
        mov	ZL, genl
        clr	ZH

        ldi	genl, (1 << BLBSET) | (1 << SPMEN)
        out_	SPMCR, genl
        rjmp	spm_do

