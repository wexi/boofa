
; Copyright (c) 2006 by Roland Riegel <feedback@roland-riegel.de>

; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License version 2 as
; published by the Free Software Foundation.

.include "m16def.inc"

; mcu clock frequency
.equ CLOCK = 14745600

; device specific boofa configuration
.equ DEVBOOTSTART = THIRDBOOTSTART
.equ DEVCODE = 0x75
.equ DEVSIG = 0x1e9403
.equ DEVELPM = 0

; device specific register handling
.equ SPMCSR = SPMCR
.equ RWWSRE = ASRE
.equ UCSRC_SELECT = (1 << URSEL)

