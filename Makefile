
MAIN := boofa
ASM := $(MAIN).asm
HEX := $(MAIN).hex
EEP_HEX := $(MAIN).eep.hex
LIST := $(MAIN).list
MAP := $(MAIN).map
OBJ := $(MAIN).obj
COF := $(MAIN).cof
SOURCES := $(wildcard *.asm)

all: $(HEX)

clean:
	rm -f $(HEX) $(LIST) $(MAP) $(EEP_HEX) $(OBJ) $(COF)

flash: $(HEX)
	avrdude -y -p m16 -U flash:w:$<

$(HEX): $(SOURCES)
	avra -l $(LIST) -m $(MAP) $(ASM)

.PHONY: all clean flash

