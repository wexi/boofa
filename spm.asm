
; Copyright (c) 2006 by Roland Riegel <feedback@roland-riegel.de>

; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License version 2 as
; published by the Free Software Foundation.

        ; waits until spm operation is complete
spm_wait:
        push gen1

spm_wait_loop:
.if SPMCSR > 0x3f
        lds gen1, SPMCSR
.else
        in gen1, SPMCSR
.endif
        sbrc gen1, SPMEN
        rjmp spm_wait_loop

        pop gen1
        ret

        ; reenable the application read-while-write section
spm_rww_enable:
        push gen1

        ldi gen1, (1 << RWWSRE) | (1 << SPMEN)
.if SPMCSR > 0x3f
        sts SPMCSR, gen1
.else
        out SPMCSR, gen1
.endif
        spm
        rcall spm_wait

        pop gen1
        ret

