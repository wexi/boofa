
; Copyright (c) 2006 by Roland Riegel <feedback@roland-riegel.de>

; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License version 2 as
; published by the Free Software Foundation.

flash_erase:
        movw	XH:XL, zeroh:zerol

flash_erase_page:
        rcall	flash_set_addr

        ldi	gen1, (1 << PGERS) | (1 << SPMEN)
        out_	SPMCSR, gen1
        rcall	spm_do

        ldi	gen1, LOW(PAGESIZE)
        add	XL, gen1
        ldi	gen1, HIGH(PAGESIZE)
        adc	XH, gen1

        ldi	gen1, LOW(DEVBOOT)
        cp	XL, gen1
        ldi	gen1, HIGH(DEVBOOT)
        cpc	XH, gen1
        brlo	flash_erase_page

	movw	XH:XL, zeroh:zerol
        ret

flash_read_word:
        rcall	flash_set_addr
        lpm_	gen1, Z+
        lpm_	gen2, Z+
        ret
        
flash_write_word:
        ldi	gen1, (1 << SPMEN)
        out_	SPMCSR, gen1
        rjmp	spm_do

flash_write_page:
        ldi	gen1, (1 << PGWRT) | (1 << SPMEN)
        out_	SPMCSR, gen1
        rcall	spm_do
        rjmp	spm_rww_enable

flash_set_addr:
        movw	ZH:ZL, XH:XL
        lsl	ZL
        rol	ZH
.if FLASHEND >= 0x8000
	rol	zerol
	out_	RAMPZ, zerol
	ror	zerol
.endif
        ret
