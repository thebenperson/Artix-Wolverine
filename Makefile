# default module to test
test := top

# default build target
all: bin/a.out

# simulation target
bin/a.out: $(wildcard src/*.sv) src/font.hex src/text.hex tests/$(test).sv
	iverilog -g 2012 -W all $(wildcard src/*.sv) tests/$(test).sv -o $@

# font target
src/font.hex: res/font.psfu tools/genfont.sh
	./tools/genfont.sh $< > $@

# text target
src/text.hex: res/text.txt tools/gentext.sh
	./tools/gentext.sh < $< > $@

# run target
test: bin/a.out
	sh -c "cd src && vvp ../$^ -fst"

export: src/font.hex src/text.hex

# clean target
clean: FORCE
	rm $(wildcard bin/* src/*.hex) dump.fst

FORCE:
