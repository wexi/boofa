
; Copyright (c) 2006 by Roland Riegel <feedback@roland-riegel.de>

; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License version 2 as
; published by the Free Software Foundation.

flash_erase:
        movw	xh:xl, zeroh:zerol

flash_erase_page:
	mov	genh, xh
	lsr	genh
	cpi	genh, DEVBOOT/512
	breq	flash_erase_next ;skip bootloader area

        rcall	flash_set_addr
        ldi	genl, (1 << PGERS) | (1 << SPMEN)
        out_	SPMCR, genl
        rcall	spm_do

flash_erase_next:
	addiw	x, PAGESIZE
	andiw	x, FLASHEND
	tstw	x
	brne	flash_erase_page
        ret

flash_read_word:
        rcall	flash_set_addr
        lpm_	genl, Z+
        lpm_	genh, Z+
        ret
        
flash_write_word:
        ldi	genl, (1 << SPMEN)
        out_	SPMCR, genl
        rjmp	spm_do

flash_write_page:
        ldi	genl, (1 << PGWRT) | (1 << SPMEN)
        out_	SPMCR, genl
        rcall	spm_do
        rjmp	spm_rww_enable

flash_set_addr:
        movw	zh:zl, xh:xl
        lsl	zl
        rol	zh
.if FLASHEND >= 0x8000
	rol	zerol
	out_	RAMPZ, zerol
	ror	zerol
.endif
        ret
