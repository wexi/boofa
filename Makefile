# EXTRA (-D) definitions:
# DEBUG -- invoke boofa unconditionally
# BIGFOOT -- place BOOFA starting at LARGEBOOTSTART
# OEM -- replace "Z" command string with oem.asm 
# PANIC -- leave programming mode if trying to rewrite the boot sector
EXTRA := -D OEM -D DEBUG

MAIN := boofa
ASM := $(MAIN).asm
HEX := $(MAIN).hex
LIST := $(MAIN).lst
SOURCES := $(wildcard *.asm)
DEF := m162def.inc
MCU := atmega162
MFC := m162
DEV := /dev/ttyUSB0
JTAG ?= 2

ATMEL := $(HOME)/avr/Atmel/AVR\ Tools/AvrAssembler2
XASM := wine $(ATMEL)/avrasm2.exe -fI -I $(ATMEL)/Appnotes
ifeq ($(JTAG),1)
DUDE := avrdude -P $(DEV) -c jtag1 -B 4 -p $(MFC)
ICE  := avarice --jtag $(DEV) --jtag-bitrate 125 --part $(MCU)
endif
ifeq ($(JTAG),2)
DUDE := avrdude -P usb -c jtag2 -p $(MFC)
ICE  := avarice --jtag usb --mkII --part $(MCU)
endif

ifeq (,$(findstring BIGFOOT,$(EXTRA)))
ifeq (,$(findstring DEBUG,$(EXTRA)))
# 512w Flash, OCDEN disabled 
HFUSE := 0xBA
else
# 512w Flash, OCDEN enabled
HFUSE := 0x3A
endif
else
ifeq (,$(findstring DEBUG,$(EXTRA)))
# 1024w Flash, OCDEN disabled
HFUSE := 0xB8
else
# 1024w Flash, OCDEN enabled 
HFUSE := 0x38
endif
endif

all: $(HEX)

$(HEX): $(SOURCES) Makefile
	$(XASM) $(EXTRA) -o $(HEX) -l $(LIST) -i $(DEF) $(ASM)

install: $(HEX)
	$(DUDE) -e -U flash:w:$(HEX):i -U efuse:w:0xFD:m -U hfuse:w:$(HFUSE):m -U lfuse:w:0xCF:m

read-fuses:
	$(ICE) --read-fuses

reset:
	$(ICE) --reset-srst

clean:
	rm -f $(HEX) $(LIST)

.PHONY: all install read-fuses reset clean
