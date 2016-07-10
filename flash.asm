
; Copyright (c) 2006 by Roland Riegel <feedback@roland-riegel.de>

; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License version 2 as
; published by the Free Software Foundation.

flash_erase:
        movw	XH:XL, zeroh:zerol

flash_erase_page:
	mov	genh, XH
	lsr	genh
	cpi	genh, DEVBOOT/512
	breq	flash_erase_next ;skip bootloader area

        rcall	flash_set_addr
        ldi	genl, (1 << PGERS) | (1 << SPMEN)
        out_	SPMCR, genl
        rcall	spm_do

flash_erase_next:
	addiw	X, PAGESIZE
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
        movw	ZH:ZL, XH:XL
        lsl	ZL
        rol	ZH
.if FLASHEND >= 0x8000
	rol	zerol
	out_	RAMPZ, zerol
	ror	zerol
.endif
        ret
