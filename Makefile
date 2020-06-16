
SHELL = /bin/sh
BIN = ./bin
BINPRIM = ./bin/prim
ASM = nasm
ASMFLAGS = -fbin

PRIMITIVES = $(BINPRIM)/holacga.com $(BINPRIM)/pixelcga.com $(BINPRIM)/sprite4.com \
              $(BINPRIM)/rebota.com $(BINPRIM)/rebota2.com $(BINPRIM)/platform.com \
              $(BINPRIM)/compcol.com $(BINPRIM)/tdycol.com $(BINPRIM)/p16doble.com


MAIN = $(BIN)/platcomp.com $(BIN)/speaker.com $(BIN)/mapedit.com \
              $(BIN)/keyboard.com $(BIN)/music.com

ALL : $(MAIN) $(PRIMITIVES)

$(BINPRIM)/holacga.com : primitiv/holacga.asm
	$(ASM) $< $(ASMFLAGS) -o $@

$(BINPRIM)/pixelcga.com : primitiv/pixelcga.asm
	$(ASM) $< $(ASMFLAGS) -o $@

$(BINPRIM)/sprite4.com : primitiv/spritecga.asm primitiv/moni
	$(ASM) $< $(ASMFLAGS) -i 'primitiv/' -o $@

$(BINPRIM)/rebota.com : primitiv/rebota.asm
	$(ASM) $< $(ASMFLAGS) -o $@

$(BINPRIM)/rebota2.com : primitiv/rebota-2.asm
	$(ASM) $< $(ASMFLAGS) -o $@

$(BINPRIM)/platform.com : primitiv/platform.asm primitiv/moni
	$(ASM) $< $(ASMFLAGS) -i 'primitiv/' -o $@

$(BINPRIM)/compcol.com : primitiv/compcol.asm
	$(ASM) $< $(ASMFLAGS) -o $@

$(BINPRIM)/tdycol.com : primitiv/tdycol.asm
	$(ASM) $< $(ASMFLAGS) -o $@

$(BINPRIM)/p16doble.com : primitiv/p16doble.asm primitiv/monocomposite
	$(ASM) $< $(ASMFLAGS) -i 'primitiv/' -o $@


$(BIN)/platcomp.com : platcomp.asm img/jugador-spritesheet.bin img/jugador-spritesheet-izq.bin img/mono-comp-8x16.bin
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
	rm bin/**/*


