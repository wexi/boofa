
; Copyright (c) 2006 by Roland Riegel <feedback@roland-riegel.de>

; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License version 2 as
; published by the Free Software Foundation.

spm_rww_enable:
        ldi	genl, (1 << RWWSRE) | (1 << SPMEN)
        out_	SPMCR, genl
spm_do:
	spm
spm_doing:
	sbic_	SPMCR, SPMEN
        rjmp	spm_doing
        ret
