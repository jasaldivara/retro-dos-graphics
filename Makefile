
SHELL = /bin/sh
BIN = ./bin
BINPRIM = ./bin/prim
ASM = nasm
ASMFLAGS = -fbin

PRIMITIVES = $(BINPRIM)/holacga.com $(BINPRIM)/pixelcga.com $(BINPRIM)/sprite4.com \
              $(BINPRIM)/rebota.com $(BINPRIM)/rebota2.com $(BINPRIM)/platform.com \
              $(BINPRIM)/compcol.com $(BINPRIM)/tdycol.com $(BINPRIM)/p16doble.com \
              $(BINPRIM)/joystick.com $(BINPRIM)/jstick2.com


MAIN =  $(BIN)/sscroll.com $(BIN)/platform.com $(BIN)/speaker.com \
	$(BIN)/mapedit.com $(BIN)/keyboard.com $(BIN)/music.com


ENGINE = engine/base.asm engine/graphics.asm engine/header.asm engine/collisions.asm \
         engine/platformer.asm engine/keyboard.asm engine/util.asm

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

$(BINPRIM)/joystick.com : primitiv/joystick.asm
	$(ASM) $< $(ASMFLAGS) -i 'primitiv/' -o $@

$(BINPRIM)/jstick2.com : primitiv/jstick2.asm
	$(ASM) $< $(ASMFLAGS) -i 'primitiv/' -o $@

$(BIN)/platform.com : games/platform.asm img/jugador-spritesheet.bin img/jugador-spritesheet-izq.bin img/enemigo-grande.bin $(ENGINE)
	$(ASM) $< $(ASMFLAGS) -o $@

$(BIN)/sscroll.com : games/sscroll.asm img/jugador-spritesheet.bin img/jugador-spritesheet-izq.bin img/enemigo-grande.bin $(ENGINE)
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
	rm bin/*.* -R


