
CPU 8086


  ; Constantes del juego


  %define GRAVEDAD 1
  %define JUMPFRAMES 12
  %define FUERZASALTO 5
  %define ANCHOTILE 8
  %define ALTOTILE 16
  %define MAPWIDTH 20
  %define MAPSCREENWIDTH 20
  %define MAPHEIGHT 12



%include 'engine/header.asm'


org 100h

section .text

start:


  call inputMenu
  test al, al
  jz .endinput
  mov word [playersprite + SPRITE.control], jscontrolfunc
  .endinput:

  ; TODO: Mover toda esta inicialización gráfica a engine/ega.asm
  ; Convertir paleta de colores de gráficos
  ; Paleta de color compuesto => Paleta de color iRGB "Tandy"
  mov bx, spritesgraphics
  mov cx, (endspritesgraphics - spritesgraphics)
  call conviertecomposite2tandy

  mov bx, tilesgraphics
  mov cx, (endtilesgraphics - tilesgraphics)
  call conviertecomposite2tandy

  mov ax, MEMEGA
  mov es, ax

  ;call videomenu
  mSetVideoMode EGALORES

  ; jmp fin


  ; TODO: Usar esto para establecer ancho de pantalla virtual
  ; Establecer Offset del control de CRT
  SetCRTControllerRegister 013h, WIDTHWORDS
  SetCRTControllerRegister 1, 25h


  ; TODO: Mover esto a engine/ega.asm
  CopiaConvierteGraficosEGA (endtilesgraphics - tilesgraphics) / 4, 2, tilesgraphics, 0

  ; TODO: Almacenar desplazamientos de sprite en estructuras SPRITE
  CopiaConvierteGraficosEGA (endspritesgraphics - spritesgraphics) / 4, 2, spritesgraphics, 0
  ;CopiaConvierteGraficosEGA (endspritesgraphics - spritesgraphics) / 4, 2, spritesgraphics, 2
  ;CopiaConvierteGraficosEGA (endspritesgraphics - spritesgraphics) / 4, 2, spritesgraphics, 4
  ;CopiaConvierteGraficosEGA (endspritesgraphics - spritesgraphics) / 4, 2, spritesgraphics, 6

  ; TODO: Mover esto a engine/ega.asm
  ; Activar todos los planos
  SelectAllPlanes
  SetGraphicsControllerRegister GRAPHICS_MODE_REG, 1 ; MODO 1 para copia en bloque


  ; SAVEINT 9h,kb_int_old	; Guardar Rutina de interrupcion del teclado del sistema (BIOS)

  ; REGISTERINT 9h,cs,kb_int_new	; Registrar nueva rutina de interrupción del teclado

  ; jmp fin

  ; Inicializar gráficos

  ; SPRITESHEETLOOP
  ; call initsprite.ega
  ; SPRITESHEETLOOPEND


  ; SPRITELOOP
  ; call conectaspritegraficos
  ; SPRITELOOPEND

  ; x .- Draw map
  mov dx, map1
  call drawmap.ega

  call esperatecla

  jmp fin
  ; 4 .- Dibujar sprite en su posicion inicial

  SPRITELOOP
  call dibujasprite16
  SPRITELOOPEND


  ;jmp fin	; Temporal

  frame:

  mov al, [tecla_esc] ; ¿está presionada esta tecla?
  test al, al
  jnz fin

  SPRITELOOP
  xor al, al
  mov bx, [ds:bp + SPRITE.control]
  test bx, bx
  jz .fincontrol
  call bx
  .fincontrol:
  call [ds:bp + SPRITE.frame]
  ; call spritecollisions
  SPRITELOOPEND

  VSync

  SPRITELOOP
  call borraspritemov
  SPRITEUPDATECOORD
  call dibujasprite16
  SPRITELOOPEND



  ; repetir ciclo
  jmp frame


esperatecla:

  wl:             ; mark wl
  mov ah, 1        ; 0 - keyboard BIOS function to get keyboard scancode
  int 16h         ; keyboard interrupt
  jz wl           ; if 0 (no button pressed) jump to wl
  ret


fin:
  ; 1 .- Reestablecer rutina original de manejo de teclado

  ; REGISTERINTMEMORY 9h, kb_int_old

  ; 2 .- Restablecer desplazamiento horizontal en registros CGA

  ; mov dx, 03d4h
  ; mov al, 0dh
  ; out dx, al
  ; mov al, 0
  ; mov dx, 03d5h
  ; out dx, al

  ; 3 .- Restablecer video modo de texto a color


  mov  ah, SETVIDEOMODE   ; Establecer modo de video
  mov  al, 3      ; CGA Modo texto a color, 80 x 25
  int  VIDEOBIOS   ; LLamar a la BIOS para servicios de video


  ; 4 .- Salir al sistema
  int 20h




%include 'engine/base.asm'
%include 'engine/keyboard.asm'
%include 'engine/joystick.asm'
%include 'engine/graphics.asm'
%include 'engine/ega.asm'
%include 'engine/collisions.asm'
%include 'engine/platformer.asm'
%include 'engine/util.asm'



section .data
  ; program data



  kb_int_old: dd  0

  ; Variables del programa:

  paleta:
  db 1

  spritesheetscount:	dw 4

  spritesheetsstrucdata:

  spritesheetmono1:
    istruc SPRITESHEET
    at SPRITESHEET.framescount, dw 18
    at SPRITESHEET.h, dw 32
    at SPRITESHEET.w, dw 8
    at SPRITESHEET.gr0, dw spritedatamonigote
    at SPRITESHEET.4colgr, dw spritedatamonigote
    at SPRITESHEET.16colgr, dw spritedatamonigote

  spritesheetgrande:
    istruc SPRITESHEET
    at SPRITESHEET.framescount, dw 1
    at SPRITESHEET.h, dw 32
    at SPRITESHEET.w, dw 16
    at SPRITESHEET.gr0, dw spritedatamonogrande
    at SPRITESHEET.4colgr, dw spritedatamonogrande
    at SPRITESHEET.16colgr, dw spritedatamonogrande

  spritesheetmonochico:
    istruc SPRITESHEET
    at SPRITESHEET.framescount, dw 1
    at SPRITESHEET.h, dw 16
    at SPRITESHEET.w, dw 8
    at SPRITESHEET.gr0, dw spritedatamonochico
    at SPRITESHEET.4colgr, dw spritedatamonochico
    at SPRITESHEET.16colgr, dw spritedatamonochico

  spritesheetmona:
    istruc SPRITESHEET
    at SPRITESHEET.framescount, dw 1
    at SPRITESHEET.h, dw 32
    at SPRITESHEET.w, dw 8
    at SPRITESHEET.gr0, dw spritedatamona
    at SPRITESHEET.4colgr, dw spritedatamona
    at SPRITESHEET.16colgr, dw spritedatamona

  playersprite:
    istruc ANIMSPRITEPHYS
    at SPRITE.frame, dw animphysspriteframe
    at SPRITE.control, dw kbcontrolfunc
    at SPRITE.ctrlcoll, dw spritephyscol
    at SPRITE.ctrlout, dw spritephysout
    at SPRITE.iavars, dw 0
    at SPRITE.x, dw 40d
    at SPRITE.y, dw 16d
    at SPRITE.nx, dw 0
    at SPRITE.ny, dw 0
    at SPRITE.h, dw 32
    ; at SPRITE.w, dw 8
    at SPRITE.next, dw playersprite2
    at SPRITE.spritesheet, dw spritesheetmono1
    at SPRITE.ssframe, dw 0
    at SPRITEPHYS.vuelox, dw 0
    at SPRITEPHYS.deltay, dw 0
    at SPRITEPHYS.saltoframes, db 0
    at SPRITEPHYS.parado, db 0
    at ANIMSPRITEPHYS.direccion, db 0
    at ANIMSPRITEPHYS.aframecount, db 0

  playersprite2:
    istruc SPRITEPHYS
    at SPRITE.frame, dw sphysicsframe
    at SPRITE.control, dw iabasiccontrol
    at SPRITE.ctrlcoll, dw iabasiccoll
    at SPRITE.ctrlout, dw spritephysout
    at SPRITE.iavars, dw LEFT
    at SPRITE.x, dw 40d
    at SPRITE.y, dw 80d
    at SPRITE.nx, dw 0
    at SPRITE.ny, dw 0
    ; at SPRITE.h, dw 32
    ; at SPRITE.pxw, dw 16
    at SPRITE.next, dw 0
    at SPRITE.spritesheet, dw spritesheetgrande
    at SPRITEPHYS.vuelox, dw 0
    at SPRITEPHYS.deltay, dw 0
    at SPRITEPHYS.saltoframes, db 0
    at SPRITEPHYS.parado, db 0

  firstsprite:
  dw playersprite



map1:


  db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 3, 4, 5, 0, 0, 0, 0, 0
  db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6, 0, 0
  db 2, 3, 4, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 6, 0, 0, 0
  db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  db 0, 0, 0, 0, 0, 0, 0, 6, 6, 0, 0, 6, 0, 0, 0, 0, 0, 0, 2, 3
  db 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 6, 0, 0, 0, 0, 0, 0, 0
  db 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6, 1, 2, 0, 0, 0, 0, 0, 0
  db 1, 4, 5, 3, 1, 2, 4, 5, 5, 4, 4, 1, 1, 2, 3, 4, 5, 5, 4, 4


colorbackground: db 77h


align   8,db 0

spritesgraphics:
spritedatamonigote:

incbin	"img/jugador-spritesheet-izq.bin",0,1152
incbin	"img/jugador-spritesheet.bin",0,1152

spritedatamona:
incbin	"img/mona-alta-8x32.bin",0,128

spritedatamonochico:
incbin "img/mono-comp-8x16.bin", 0, 64

spritedatamonogrande:
incbin "img/enemigo-grande.bin", 0, 256

endspritesgraphics:

tilesgraphicscount:	db	7


align   8,db 0

tilesgraphics:
incbin "img/tile0.bin",0,64
incbin "img/tile1.bin",0,64
incbin "img/tile2.bin",0,64
incbin "img/tile3.bin",0,64
incbin "img/tile4.bin",0,64
incbin "img/tile5.bin",0,64
incbin "img/tile6.bin",0,64

endtilesgraphics:

section .bss
  ; uninitialized data

memorialibre:

