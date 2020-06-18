
  %use ifunc

  %define VIDEOBIOS 0x10
  %define SETVIDEOMODE 0
  %define CGA6 0x06
  %define WIDTHPX 160d
  %define HEIGHTPX 200d
  %define PXB 2   ; Pixeles por byte
  %define BYTESPERHSCROLL 2	; Bytes que se desplazan cada vez que se hace scroll horizontal
  %assign BYTESPERSCAN (WIDTHPX / PXB)

  %define MEMCGAEVEN 0xB800
  %define MEMCGAODD 0xBA00

  %define KB_ESC 01
  %define KB_UP 48h
  %define KB_DOWN 50h
  %define KB_LEFT 4Bh
  %define KB_RIGHT 4Dh


  %define HSCROLLSPERTILE ( ANCHOTILE / ( PXB * BYTESPERHSCROLL ) )
  %define MAXHSCROLL ( ( MAPWIDTH - MAPSCREENWIDTH ) * HSCROLLSPERTILE )


  ; Direcciones
  ; Para controles y detección de colisiones

  %define UP		00001000b
  %define DOWN		00000100b
  %define LEFT		00000010b
  %define RIGHT		00000001b

  ; data structures

  ; Game specific constants



  struc SPRITESHEET
    .framescount:	resw 1	; Cantidad de frames que contiene el sprite
    .h			resw 1
    .w			resw 1
    .gr0:		resw 1
    .gr1:		resw 1
    .4colgr:		resw 1
    .16colgr:		resw 1
  endstruc

  struc SPRITE

    .frame:	resw 1	; Pointer to function defining per frame logic
    .control:	resw 1  ; Pointer to control function. Could be keyboard or joystick player, or A.I.
    .ctrlcoll:	resw 1	; Pointer to controll collision event. Called when the sprite have a collision.
    .ctrlout:	resw 1	; Pointer tu event handler, when go out of scene
    .iavars	resw 1	; I.A. reserved variables.
    .x		resw 1
    .y		resw 1
    .nx		resw 1
    .ny		resw 1
    .h		resw 1
    .pxw		resw 1
    .bw	resw 1
    .next	resw 1	; Pointer to nexts prite in linked list
    .spritesheet	resw 1	; Pointer to SPRITESHEET structure
    .ssframe	resw 1	; Frame index in sprite sheet
    .gr0:	resw 1	; Pointer to graphic data
    .gr1:	resw 1	; Pointer to graphic data

  endstruc

  struc SPRITEPHYS	; Sprite with Physics

    .sprite:	resb SPRITE_size
    .vuelox:	resw 1
    .vxmax:	resw 1
    .deltay:	resw 1
    .saltoframes:	resb 1
    .parado:	resb 1

  endstruc

  struc ANIMSPRITEPHYS	; Animated Sprite with Physics

    .sprite:	resb SPRITEPHYS_size
    .direccion: resb 1
    .aframecount: resb 1

  endstruc

  ; Macros

  ; vsync: Esperar retrazo vertical
  %macro VSync 0

  MOV	DX, 03DAH

  %%Retrace1:
	IN	AL,DX			; AL := Port[03DAH]
	TEST	AL,8			; Is bit 3 set?
	JZ	%%Retrace1		; No, continue waiting

	%%Retrace2:				;	IN	AL,DX
	IN	AL,DX		; AL := Port[03DAH]
	TEST	AL,8			; Is bit 3 unset?
	JNZ	%%Retrace2		; No, continue waiting

  %endmacro

  ; NYT: Nivel de tile vertical
  ; Calcula el nivel vertical en tiles al que pertenece una coordenada Y en pixeles
  %macro NYT 1
  %rep ilog2e( ALTOTILE )
  shr %1, 1
  %endrep
  %endmacro

  ; NXT: Nivel de tile horizontal
  ; Calcula el nivel horizontal en tiles al que pertenece una coordenada X en pixeles
  %macro NXT 1
  %rep ilog2e( ANCHOTILE )
  shr %1, 1
  %endrep
  %endmacro

  ; PYT: Pixel de tile vertical
  ; Calcula la coordenada Y en pixeles a la que corresponde un nivel Y de Tiles
  %macro PYT 1
  %rep ilog2e( ALTOTILE )
  shl %1, 1
  %endrep
  %endmacro

  ; PXT: Nivel de tile horizontal
  ; Calcula la coordenada X en pixeles a la que corresponde un nivel X de Tiles
  %macro PXT 1
  %rep ilog2e( ANCHOTILE )
  shl %1, 1
  %endrep
  %endmacro

  ; SPRITELOOP: Recorrer lista de Sprites
  %macro SPRITELOOP 0

    %push spriteloop
    mov ax, [firstsprite]
    test ax, ax
    jz %$end
    mov bp, ax
    %$begin:

  %endmacro

  %macro SPRITELOOPEND 0

    mov ax, [ds:bp + SPRITE.next]
    test ax, ax
    jz %$end
    mov bp, ax
    jmp %$begin
    %$end:

    %pop spriteloop

  %endmacro

  %macro SPRITESHEETLOOP 0

    %push spritesheetloop

    mov cx, [spritesheetscount]
    mov bp, spritesheetsstrucdata
    %$begin:
    push cx

  %endmacro


  %macro SPRITESHEETLOOPEND 0
    pop cx
    add bp, SPRITESHEET_size
    loop %$begin

    %pop spritesheetloop
  %endmacro

  %macro SPRITEUPDATECOORD 0
    mov bx, bp
    mov ax, [bx + SPRITE.ny]
    mov [bx + SPRITE.y], ax
    mov ax, [bx + SPRITE.nx]
    mov [bx + SPRITE.x], ax
  %endmacro


  %macro SAVEINT 2
    ; %1 => Interrupt Number
    ; %2 => Double Word, space in memory to save it
    mov al, %1
    mov ah, 35h
    int 21h
    mov [%2], bx
    mov [%2 + 2], es
  %endmacro

  %macro REGISTERINT 3
    ; %1 => Interrupt Number
    ; %2 => New Interrupt Segment
    ; %3 => New Interrupt Address
    mov al, %1
    mov ah, 25h
    mov bx, %2
    mov dx, %3
    mov ds, bx
    int 21h
  %endmacro

  %macro REGISTERINTMEMORY 2
    ; %1 => Interrupt Number
    ; %2 => Double Word, space in memory to load it
    mov al, %1
    mov ah, 25h
    mov dx, [%2]
    mov bx, [%2 + 2]
    mov ds, bx
    int 21h
  %endmacro




