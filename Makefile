# EXTRA (-D) definitions:
# DEBUG -- invoke boofa unconditionally, enable OCD
# BIGFOOT -- place BOOFA starting at LARGEBOOTSTART
# OEM -- replace "Z" command string with oem.asm 
# PANIC -- leave programming mode if trying to rewrite the boot sector
EXTRA := -D OEM

MAIN := boofa
ASM := $(MAIN).asm
HEX := $(MAIN).hex
LIST := $(MAIN).lst
SOURCES := $(wildcard *.asm)
DEF := m162def.inc
MCU := atmega162
MFC := m162
TTY := /dev/ttyUSB1

ATMEL := $(HOME)/avr/Atmel/AVR\ Tools/AvrAssembler2
XASM := wine $(ATMEL)/avrasm2.exe -fI -I $(ATMEL)/Appnotes
DUDE := avrdude -P usb -c jtag2 -p $(MFC)
ICE  := avarice --jtag usb --mkII --part $(MCU)

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

tty:
	avrdude -P $(TTY) -b 38400 -c avr109 -p $(MFC) -t

clean:
	rm -f $(HEX) $(LIST)

.PHONY: all install read-fuses reset tty clean
