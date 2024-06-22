DEV := /dev/ttyUSB0
MCU := attiny85
PROGRAMMER := avrisp
BAUD := 19200

PROJECT := leds

SOURCES := $(wildcard src/*.asm)
OBJECTS := $(patsubst %.asm,%.obj,${SOURCES})

TARGET = main

main: build/
	avra -I src \
		-e build/${PROJECT}.eep.hex \
		-o build/${PROJECT}.hex \
		${SOURCES}

build/:
	mkdir build

upload: main
	avrdude -p ${MCU} \
		-P ${DEV} \
		-c ${PROGRAMMER} \
		-b ${BAUD} \
		-U flash:w:build/${PROJECT}.hex

clean:
	rm -rf build ${OBJECTS}
