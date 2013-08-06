
; Copyright (c) 2006 by Roland Riegel <feedback@roland-riegel.de>

; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License version 2 as
; published by the Free Software Foundation.

.include "m128def.inc"

; mcu clock frequency
.equ CLOCK = 14745600

; device specific boofa configuration
.equ DEVBOOTSTART = LARGEBOOTSTART
.equ DEVCODE = 0x44
.equ DEVSIG = 0x1e9702
.equ DEVELPM = 1

; device specific register handling
.equ UBRRH = UBRR0H
.equ UBRRL = UBRR0L
.equ UDR = UDR0
.equ UCSRA = UCSR0A
.equ UCSRB = UCSR0B
.equ UCSRC = UCSR0C
.equ UCSRC_SELECT = 0

