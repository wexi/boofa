
; Copyright (c) 2006 by Roland Riegel <feedback@roland-riegel.de>

; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License version 2 as
; published by the Free Software Foundation.

        ; reads a single byte from eeprom memory
eeprom_read: ; XH:XL (in,out): address
             ; genl (out): data
        sbic_	EECR, EEWE
        rjmp	eeprom_read
	
        out_	EEARH, XH
        out_	EEARL, XL
        sbi_	EECR, EERE
        in_	genl, EEDR

        ret

        ; writes a single byte to eeprom memory
eeprom_write: ; XH:XL (in,out): address
              ; genl (in): data byte

        sbic_	EECR, EEWE
        rjmp	eeprom_write

        out_	EEARH, XH
        out_	EEARL, XL
        out_	EEDR, genl

        sbi_	EECR, EEMWE
        sbi_	EECR, EEWE
        
        ret

