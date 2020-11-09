
  %use ifunc

  %define VIDEOBIOS 0x10
  %define SETVIDEOMODE 0
  %define CGA4COLOR 0x04
  %define EGALORES  0x0D
  %define WIDTHPX 320d
  %define WIDTHBYTES 40d
  %define HEIGHTPX 200d

  %define MEMEGA      0xA000
  %define MEMCGAEVEN 0xB800
  %define MEMCGAODD 0xBA00
  %define EGAPXPERBYTE  8d

  %define EGAIMGDATA  0x2000

  ; registros EGA
  %define GRAPHICS_MODE_REG 5

  ; teclado

  %define KB_ESC 01
  %define KB_UP 48h
  %define KB_DOWN 50h
  %define KB_LEFT 4Bh
  %define KB_RIGHT 4Dh
  %define KB_SALTA 44d
  %define KB_ACCION 45d

  ; Constantes del juego

  %define ANCHOTILE 16
  %define ALTOTILE 16
  %define MAPWIDTH 20
  %define MAPSCREENWIDTH 20
  %define MAPHEIGHT 12

  ; Aritmetica de constantes gráficas
  %define ANCHOTILEBYTES    (ANCHOTILE / EGAPXPERBYTE)

  %define IDSPRITE(s)   ((s - tilesgraphics) / 64)

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

org 100h

section .text

start:

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

  ; Entrar en modo EGA 16 colores 320 x 200
  mov  ah, SETVIDEOMODE   ; Establecer modo de video
  mov  al, EGALORES      ; EGA 16 Colores 320 x 200
  int  VIDEOBIOS   ; LLamar a la BIOS para servicios de video


  push (endtilesgraphics - tilesgraphics) / 2
  push tilesgraphics
  push 0
  ;push ax
  call copiagraficos

  push (endspritesgraphics - spritesgraphics) / 2
  push spritesgraphics
  push 4
  ;push ax
  call copiagraficos

  ; Activar todos los planos
  SelectAllPlanes

  SetGraphicsControllerRegister GRAPHICS_MODE_REG, 1 ; MODO 1 para copia en bloque

  ;mov ax, 2
  ;mov bx, 2
  ;mov cx, 6
  ;call drawtileEGA


  ; x .- Draw map
  mov dx, map1
  call drawmap

  ; y .- Dibujar sprite
  mov cx, IDSPRITE(spritedatamonochico)
  mov ax, [spritey]
  mov bx, [spritex]
  call drawtileEGA

  .cicloteclado:
  mov ah, 1   ; "Get keystroke status"
  int 16h
  jz .cicloteclado

  ; Borrar tecla presionada de buffer del teclado
  mov ah, 0
  int 16h

  cmp ah, KB_ESC
  je end
  cmp ah, KB_UP
  jne .noarriba
  call movup
  .noarriba:
  cmp ah, KB_DOWN
  jne .noabajo
  call movdown
  .noabajo:
  cmp ah, KB_LEFT
  jne .noizq
  call movleft
  .noizq:
  cmp ah, KB_RIGHT
  jne .noder
  call movright
  .noder:
  cmp al, '-'
  jne .noscrollarriba
  mov al, [vscroll]
  dec al
  mov [vscroll], al
  call dovscroll
  jmp .cicloteclado
  .noscrollarriba:
  cmp al, ' '
  jne .nomodo
  call cambiamodo
  jmp .cicloteclado
  .nomodo:
  cmp al, '+'
  jne .cicloteclado
  mov al, [vscroll]
  inc al
  mov [vscroll], al
  call dovscroll
  jmp .cicloteclado

end:

  ; Restablecer video modo de texto a color
  mov  ah, SETVIDEOMODE   ; Establecer modo de video
  mov  al, 3      ; CGA Modo texto a color, 80 x 25
  int  VIDEOBIOS   ; LLamar a la BIOS para servicios de video

  ;  Salir al sistema
  int 20h

movup:
mov ax, [spritey]
cmp ax, 0
jng .ret
dec ax
mov [spritey], ax
call movsprite
.ret:
ret
movdown:
mov ax, [spritey]
cmp ax, MAPHEIGHT - 1
jnl .ret
inc ax
mov [spritey], ax
call movsprite
.ret:
ret
movleft:
mov ax, [spritex]
cmp ax, 0
jng .ret
dec ax
mov [spritex], ax
call movsprite
.ret:
ret
movright:
mov ax, [spritex]
cmp ax, MAPWIDTH - 1
jnl .ret
inc ax
mov [spritex], ax
call movsprite
.ret:
ret

movsprite:

  ;SetGraphicsControllerRegister GRAPHICS_MODE_REG, 0
  ;SetGraphicsControllerRegister 3, 00011000b
  ;SetGraphicsControllerRegister 8, 00001111b


  VSync

  ; 1.- Borrar anterior tile
  mov dx, map1
  mov si, dx
  mov al, [spriteay]
  mov ah, MAPWIDTH
  mul ah
  add ax, [spriteax]
  add si, ax
  lodsb
  xor ah, ah
  mov cx, ax
  mov ax, [spriteay]
  mov bx, [spriteax]
  call drawtileEGA

  ; 2.- Dibujar nuevo sprite
  mov cx, IDSPRITE(spritedatamonochico)
  mov ax, [spritey]
  mov bx, [spritex]
  call drawtileEGA

  ; 3.- Actualizar coordenadas
  mov [spriteay], ax
  mov [spriteax], bx


ret

copiagraficos:
  push bp
  mov bp, sp
  sub sp, 2   ; variables locales * 2

  ; [bp + 8] = cantidad de palabras (2 bytes) a copiar
  ; [bp + 6] = direccion de origen a copiar
  ; [bp + 4] = pixel offset
  ; [bp + 2] = saved ip (return address)
  ; [bp] = saved bp
  ; [bp - 2] = local 1 (pixeles siguientes temporal)


  mov cx, 3     ; dl = plano a copiar

  .cicloplanos:


  SelectPlaneNumber   ; Numero de plano en cl

  ; ciclo de copiado
  mov dx, cx	; dx = plano a copiar

  ; Llenar espacio vacío de desplazamiento
  mov al, 0ffh
  mov cx, [bp + 4] ; cx = pixel offset
  shr al, cl
  not al
  mov [bp - 2], al

  mov cx, [bp + 8]	; cx = cantidad de palabras a copiar

  ; Establecer direccion es origen y destino
  ; Origen = RAM, Destino = VRAM
  mov ax, [ega_alloc_end]
  mov di, ax    ; ES:DI => Inicio de EGA Buffer en VRAM
  mov si, [bp + 6]    ; direccion de origen a copiar


  .ciclocopia:
  push cx

  call convierteabitplano

  ;add di, WIDTHBYTES - 2
  pop cx
  loop .ciclocopia

  mov bx, [bp + 4]  ; Pixel offset
  test bx, bx
  jz .sigpilon
  mov al, [bp-2]  ; ultimo byte almacenado
  ; TODO: Agregar color de relleno
  mov al, 0ffh
  ;mov ax, 0ffffh
  stosb  ; Copiar a VRAM
  .sigpilon:
  mov cx, dx

  dec cx
  jge .cicloplanos
  ;loop .cicloplanos


  ; TODO: ¿Cambiar por di?
  ;mov ax, [ega_alloc_end]
  ;add ax, [bp + 8]
  ;mov bx, [bp + 4]  ; Pixel offset
  ;test bx, bx
  ;jz .sigpilon2
  ;inc ax
  .sigpilon2:
  mov ax, di
  mov [ega_alloc_end], ax



  mov sp, bp
  pop bp

  ret


convierteabitplano:

  lodsw     ; AX = datos gráficos

  mov cl, dl	; cl = plano a copiar

  mov bl, al
  shr bl, 4   ; Procesar primero 4 bits
  shr bl, cl  ; Desplazamiento del plano actual
  and bl, 1   ; tomar solo ultimo bit
  mov bh, bl
  shl bh, 1
  or bh, bl   ; duplicar bit
  mov ch, bh  ; almacenar en ch
  shl ch, 1
  shl ch, 1   ; recorrer ch, 2 bits

  mov bl, al  ; Lo mismo, pero con siguientes 4 bits
  shr bl, cl  ; Desplazamiento del plano actual
  and bl, 1   ; tomar solo ultimo bit
  mov bh, bl
  shl bh, 1
  or bh, bl   ; duplicar bit
  or ch, bh   ; almacenar bits en ch
  shl ch, 1
  shl ch, 1   ; recorrer ch, 2 bits

  mov bl, ah
  shr bl, 4   ; Procesar primero 4 bits
  shr bl, cl  ; Desplazamiento del plano actual
  and bl, 1   ; tomar solo ultimo bit
  mov bh, bl
  shl bh, 1
  or bh, bl   ; duplicar bit
  or ch, bh  ; almacenar en ch
  shl ch, 1
  shl ch, 1   ; recorrer ch, 2 bits

  mov bl, ah  ; Lo mismo, pero con siguientes 4 bits
  shr bl, cl  ; Desplazamiento del plano actual
  and bl, 1   ; tomar solo ultimo bit
  mov bh, bl
  shl bh, 1
  or bh, bl   ; duplicar bit
  or ch, bh   ; almacenar bits en ch


  mov ah, ch
  xor al, al
  mov cl, [bp + 4] ; Desplazamiento en px?
  shr ax, cl
  mov bx, [bp - 2]	; Agregar pixeles desplazados
  mov [bp - 2], ax
  or ah, bl
  mov al, ah

  stosb       ; Almacenar byte en memoria de video

  ret


drawtileEGA:
  ; AX = Y Coordinate of tile
  ; BX = X Coordinate of tile
  ; CX = Tile Code
  push ds
  push si
  push ax	; Respaldar AX y BX
  push bx

  ; 1 .- Calcular DI (Destination Index)
  ; 1.1 .- Multiplicar para calcular desplazamiento
  mov dl, WIDTHBYTES    ; NOTA ¿usar 8 ó 16 bits?
  mul dl
  mov dx, cx
  mov cx, ilog2e( ALTOTILE )
  shl ax, cl


  ; 1.2 .- Multiplicar X por ancho de TILE
  mov cx, ilog2e(ANCHOTILEBYTES)
  shl bx, cl


  ; 1.3 .- Sumar
  add ax, bx
  mov di, ax	; Destination Index

  ; 2 .- Calcular SI (Source Index)
  mov cx, ilog2e(ALTOTILE * ANCHOTILEBYTES)
  shl dx, cl
  add dx, EGAIMGDATA
  mov si, dx

  ; 3 .- Copiar datos
  mov ax, es
  mov ds, ax

  mov cx, ALTOTILE
  .looprows:
  mov dx, cx
  mov cx, ANCHOTILEBYTES
  rep movsb
  mov cx, dx
  add di, WIDTHBYTES - ANCHOTILEBYTES
  loop .looprows

  .salir:
  pop bx	; Restaurar bx y ax
  pop ax
  pop si
  pop ds
  ret

dovscroll:

  mov al, [vscroll]
  mov ah, WIDTHBYTES
  mul ah
  mov bx, ax

  mov dx, 3D4h
  mov al, 0Ch         ; index of offset
  out dx, al

  mov dx, 3D5h
  mov al, bh
  out dx, al

  mov dx, 3D4h
  mov al, 0Dh         ; index of offset
  out dx, al

  mov dx, 3D5h
  mov al, bl
  out dx, al
ret

cambiamodo:

  mov al, [control_modo]
  mov bl, al
  test bl, bl
  jz .no
  .si:
  xor bl, bl
  mov bh, 0e3h
  jmp .sig

  .no:
  mov bl, 1
  mov bh, 11100010b

  .sig:

  mov [control_modo], bl

  mov dx, 3D4h
  mov al, 17h         ; index of offset
  out dx, al

  mov dx, 3D5h
  mov al, bh         ; index of offset
  out dx, al


ret

drawmap:
  ; DX = Map data
  xor ax, ax	; AX = 0
  mov si, dx	; Load Map data on Source index

  .looprows:

  xor bx, bx	; BX = 0
  .loopcols:
  mov cx, ax
  lodsb
  xchg ax, cx
  call drawtileEGA
  inc bx
  cmp bx, MAPSCREENWIDTH
  jl .loopcols
  inc ax
  add si, MAPWIDTH - MAPSCREENWIDTH
  cmp ax, MAPHEIGHT
  jl .looprows
  ret


conviertecomposite2tandy:
  ; bx => graficos a convertir
  ; cx => cantidad de bytes a convertir
  push si
  push di

  mov ax, cs	; Esto sólo funciona en ejecutables ".com" Cambiar en caso de ".exe"
  mov ds, ax
  mov es, ax

  mov si, bx
  mov di, bx

  mov bx, comp2tdy_table

  .loopbyte:
  lodsb
  mov dx, cx
  mov ah, al
  and al, 00001111b
  xlatb
  xchg ah, al
  mov cl, 4
  shr al, cl
  xlatb
  mov cl, 4
  shl al, cl
  or al, ah
  stosb
  mov cx, dx
  loop .loopbyte

  pop di
  pop si
  ret


section .data
  ; program data

  spritex:  dw 1
  spritey:  dw 1
  spriteax:  dw 1
  spriteay:  dw 1

  vscroll:
  db 0

  control_modo:
  db 0

  ega_alloc_end:
  dw EGAIMGDATA

  ; Trabla de equivalencia entre paletas de colores Composite => Tandy (iRGB)
  comp2tdy_table:

  db 0, 2, 1, 3, 4, 7, 5, 11, 6, 10, 8, 10, 12, 14, 13, 15


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


spritesgraphics:

spritedatamonochico:
incbin "img/mono-comp-8x16.bin", 0, 64

spritedatamonigote:

incbin	"img/jugador-spritesheet-izq.bin",0,1152
incbin	"img/jugador-spritesheet.bin",0,1152

spritedatamona:
incbin	"img/mona-alta-8x32.bin",0,128


spritedatamonogrande:
incbin "img/enemigo-grande.bin", 0, 256


endspritesgraphics:

section .bss
  ; uninitialized data

memorialibre:
