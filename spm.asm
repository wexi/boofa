
; Copyright (c) 2006 by Roland Riegel <feedback@roland-riegel.de>

; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License version 2 as
; published by the Free Software Foundation.

spm_rww_enable:
        ldi	gen1, (1 << RWWSRE) | (1 << SPMEN)
        out_	SPMCSR, gen1
spm_do:
	spm
spm_doing:
	sbic_	SPMCSR, SPMEN
        rjmp	spm_doing
        ret
