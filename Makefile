
SHELL = /bin/sh
BIN = ./bin
ASM = nasm
ASMFLAGS = -fbin

EJECUTABLES = $(BIN)/holacga.com $(BIN)/pixelcga.com $(BIN)/sprite4.com \
              $(BIN)/rebota.com $(BIN)/rebota2.com $(BIN)/platform.com \
              $(BIN)/compcol.com $(BIN)/platcomp.com $(BIN)/p16doble.com

ALL : $(EJECUTABLES)

$(BIN)/holacga.com : holacga.asm
	$(ASM) $< $(ASMFLAGS) -o $@

$(BIN)/pixelcga.com : pixelcga.asm
	$(ASM) $< $(ASMFLAGS) -o $@

$(BIN)/sprite4.com : spritecga.asm moni
	$(ASM) $< $(ASMFLAGS) -o $@

$(BIN)/rebota.com : rebota.asm
	$(ASM) $< $(ASMFLAGS) -o $@

$(BIN)/rebota2.com : rebota-2.asm
	$(ASM) $< $(ASMFLAGS) -o $@

$(BIN)/platform.com : platform.asm
	$(ASM) $< $(ASMFLAGS) -o $@ moni

$(BIN)/platcomp.com : platcomp.asm mdoble.bin
	$(ASM) $< $(ASMFLAGS) -o $@

$(BIN)/compcol.com : compcol.asm
	$(ASM) $< $(ASMFLAGS) -o $@

$(BIN)/p16doble.com : p16doble.asm monocomposite
	$(ASM) $< $(ASMFLAGS) -o $@

clean :
	rm bin/*.*


