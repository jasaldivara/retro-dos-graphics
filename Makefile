
SHELL = /bin/sh
BIN = ./bin
ASM = nasm
ASMFLAGS = -fbin

EJECUTABLES = $(BIN)/holacga.com $(BIN)/pixelcga.com $(BIN)/sprite4.com \
              $(BIN)/rebota.com $(BIN)/rebota2.com $(BIN)/platform.com \
              $(BIN)/compcol.com $(BIN)/tdycol.com $(BIN)/platcomp.com \
              $(BIN)/p16doble.com $(BIN)/speaker.com $(BIN)/mapedit.com \
              $(BIN)/keyboard.com $(BIN)/music.com

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
	$(ASM) $< $(ASMFLAGS) -o $@

$(BIN)/platcomp.com : platcomp.asm img/mono-alto-8x32-0.bin \
		img/mono-alto-8x32-2.bin img/mono-alto-8x32-3.bin \
		mona-alta-8x32.bin mono-comp-8x16.bin
	$(ASM) $< $(ASMFLAGS) -o $@

$(BIN)/compcol.com : compcol.asm
	$(ASM) $< $(ASMFLAGS) -o $@

$(BIN)/tdycol.com : tdycol.asm
	$(ASM) $< $(ASMFLAGS) -o $@

$(BIN)/p16doble.com : p16doble.asm monocomposite
	$(ASM) $< $(ASMFLAGS) -o $@

$(BIN)/speaker.com : speaker.asm
	$(ASM) $< $(ASMFLAGS) -o $@

$(BIN)/mapedit.com : mapedit.asm
	$(ASM) $< $(ASMFLAGS) -o $@

$(BIN)/keyboard.com : keyboard.asm
	$(ASM) $< $(ASMFLAGS) -o $@

$(BIN)/music.com : music.asm
	$(ASM) $< $(ASMFLAGS) -o $@

clean :
	rm bin/*.*


