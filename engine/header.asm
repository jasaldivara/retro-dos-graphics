
  %use ifunc

  %define VIDEOBIOS 0x10
  %define SETVIDEOMODE 0
  %define CGA4COLOR 0x04
  %define CGA6 0x06
  %define EGALORES  0x0D
  %define WIDTHPX 160d
  %define HEIGHTPX 200d
  %define PXB 2   ; Pixeles por byte
  %define BYTESPERHSCROLL 2	; Bytes que se desplazan cada vez que se hace scroll horizontal
  %assign BYTESPERSCAN (WIDTHPX / PXB)


  ; EGA constants
  %define WIDTHWORDS 21d
  %define WIDTHBYTES (WIDTHWORDS * 2)


  %define MEMEGA      0xA000
  %define MEMCGAEVEN 0xB800
  %define MEMCGAODD 0xBA00
  %define EGAPXPERBYTE  8d

  ; Keyboard constants

  %define KB_ESC 01
  %define KB_UP 48h
  %define KB_DOWN 50h
  %define KB_LEFT 4Bh
  %define KB_RIGHT 4Dh
  %define KB_SALTA 44d
  %define KB_ACCION 45d

  ; Joystick constants

  %define JOYSTICKPORT	201h
  %define JS2B	10000000b
  %define JS2A	01000000b
  %define JS1B	00100000b
  %define JS1A	00010000b
  %define JS2Y	00001000b
  %define JS2X	00000100b
  %define JS1Y	00000010b
  %define JS1X	00000001b



  %define HSCROLLSPERTILE ( ANCHOTILE / ( PXB * BYTESPERHSCROLL ) )
  %define MAXHSCROLL ( ( MAPWIDTH - MAPSCREENWIDTH ) * HSCROLLSPERTILE )


  ; Warning: Only 80-column text mode!
  %define BYTESPERROW	160d

  ; Direcciones
  ; Para detección de colisiones

  %define UP		00001000b
  %define DOWN		00000100b
  %define LEFT		00000010b
  %define RIGHT		00000001b


  ; Constantes de controles:

  %define BBTN   10000000b
  %define ABTN   01000000b


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


  %macro mSetVideoMode 1

  mov  ah, 0   ; Establecer modo de video
  mov  al, %1      ; Modo de video
  int  10h   ; LLamar a la BIOS para servicios de video

  %endmacro

  ; vsync: Esperar retrazo vertical
  %macro VSync 0

  MOV	DX, 03DAH


	%%Retrace2:				;	IN	AL,DX
	IN	AL,DX		; AL := Port[03DAH]
	TEST	AL,8			; Is bit 3 unset?
	JNZ	%%Retrace2		; No, continue waiting

  %%Retrace1:
	IN	AL,DX			; AL := Port[03DAH]
	TEST	AL,8			; Is bit 3 set?
	JZ	%%Retrace1		; No, continue waiting

  %endmacro


  %macro mEscribeStringzColor 3

  ; ds:bx = stringz
  ; %1 = atributos (colores)
  ; %2 = x
  ; %3 = y

  mov dh, %3
  mov dl, %2
  mov ch, %1
  call escribestringz

  %endmacro


  %macro mBorraTexto 3

  ; %1 = cantidad de caracteres
  ; %2 = x
  ; %3 = y

  mov cx, %1
  mov dl, %2
  mov dh, %3

  call borratexto

  %endmacro

  %macro readJoystick 0

  mov dx, JOYSTICKPORT
  in al, dx

  %endmacro


  %macro EsperaTiempo 0

  call esperatiempo

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





  ; %define EGAIMGDATA  0x2000
  ; %define EGAIMGDATA  (WIDTHBYTES * HEIGHTPX)
  %define EGAIMGDATA  0x4000

  ; registros EGA
  %define GRAPHICS_MODE_REG 5

  %macro WaitDisplayEnable 0

  MOV	DX, 03DAH

  %%WaitLoop:
	in	al, dx
	and	al, 1
	jnz	%%WaitLoop

  %endmacro

  %macro SelectPlaneNumber 0
  ; Colocar en cl numero de plano
  ; Destruye DX y AL

  mov dx, 3C4h       ; address of sequencer address register
  mov al, 2h         ; index of map mask register
  out dx, al

  mov dx, 3C5h        ; address of sequencer data register
  mov al, 1          ; Activar el plano actual
  shl al, cl
  out dx, al

  %endmacro


  %macro SelectAllPlanes 0
  ; Destruye DX y AL

  mov dx, 3C4h       ; address of sequencer address register
  mov al, 2h         ; index of map mask register
  out dx, al

  mov dx, 3C5h        ; address of sequencer data register
  mov al, 00001111b          ; Activar todos los planos
  out dx, al

  %endmacro

  %macro SetGraphicsControllerRegister 2

  mov dx, 3CEh       ; address of graphics controller register
  mov al, %1         ; index of register
  out dx, al

  mov dx, 3CFh
  mov al, %2         ; value of register
  out dx, al

  %endmacro

  %macro SetAttributeControllerRegister 2

  mov dx, 3C0h       ; address of graphics controller register
  mov al, %1         ; index of register
  out dx, al

  ;mov dx, 3C0h
  mov al, %2         ; value of register
  out dx, al

  %endmacro


  %macro SetCRTControllerRegister 2

  mov dx, 3D4h
  mov al, %1	; Numero de registro a cambiar
  out dx, al

  mov dx, 3D5h
  mov al, %2	; Nuevo valor del registro
  out dx, al

  %endmacro

  %macro CopiaConvierteGraficosEGA 4

  ; %1 = cantidad de ciclos
  ; %2 = cantidad de palabras (2 bytes) de ancho
  ; %3 = direccion de origen a copiar
  ; %4 = pixel offset

  mov ax, %1
  push ax
  mov ax, %2
  push ax
  mov ax, %3
  push ax
  mov ax, %4
  push ax
  call copiagraficos.ega
  add sp, 8	; Restablecer pila

  %endmacro


