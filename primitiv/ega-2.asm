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


  %define KB_ESC 01
  %define KB_UP 48h
  %define KB_DOWN 50h
  %define KB_LEFT 4Bh
  %define KB_RIGHT 4Dh
  %define KB_SALTA 44d
  %define KB_ACCION 45d

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


  call copiagraficos


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
  .siarriba:
  mov al, [vscroll]
  dec al
  mov [vscroll], al
  call dovscroll
  jmp .cicloteclado
  .noarriba:
  cmp ah, KB_DOWN
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

copiagraficos:
  

  mov cx, 3     ; dl = plano a copiar

  .cicloplanos:


  SelectPlaneNumber   ; Numero de plano en cl

  ; ciclo de copiado
  mov dx, cx
  mov cx, (endtilesgraphics - tilesgraphics) / 4
  ;mov cx, 40h

  ; Establecer direccion es origen y destino
  ; Origen = RAM, Destino = VRAM
  xor ax, ax
  mov di, ax    ; ES:DI => Inicio de EGA Buffer
  mov ax, tilesgraphics
  mov si, ax    ; DS:SI => Tiles gráficos

  .ciclocopia:
  ;push bx
  push cx

  mov cl, dl

  call convierteabitplano
  call convierteabitplano


  add di, WIDTHBYTES - 2
  pop cx
  ;pop bx
  loop .ciclocopia

  mov cx, dx

  dec cx
  jge .cicloplanos
  ;loop .cicloplanos

  mov cx, 3     ; dl = plano a copiar

  .cicloplanos2:


  SelectPlaneNumber   ; Numero de plano en cl

  ; ciclo de copiado
  mov dx, cx
  mov cx, (endspritesgraphics - spritesgraphics) / 4
  ;mov cx, 40h

  ; Establecer direccion es origen y destino
  ; Origen = RAM, Destino = VRAM
  mov ax, 2
  mov di, ax    ; ES:DI => Inicio de EGA Buffer
  mov ax, spritesgraphics
  mov si, ax    ; DS:SI => Tiles gráficos

  .ciclocopia2:
  ;push bx
  push cx

  mov cl, dl

  call convierteabitplano
  call convierteabitplano


  add di, WIDTHBYTES - 2
  pop cx
  ;pop bx
  loop .ciclocopia2

  mov cx, dx

  dec cx
  jge .cicloplanos2


  ret

convierteabitplano:

  lodsw     ; AX = datos gráficos

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


  mov al, ch
  stosb       ; Almacenar byte en memoria de video

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

  vscroll:
  db 0

  ; Trabla de equivalencia entre paletas de colores Composite => Tandy (iRGB)
  comp2tdy_table:

  db 0, 2, 1, 3, 4, 7, 5, 11, 6, 10, 8, 10, 12, 14, 13, 15

align   8,db 0

tilesgraphics:
incbin "../img/tile0.bin",0,64
incbin "../img/tile1.bin",0,64
incbin "../img/tile2.bin",0,64
incbin "../img/tile3.bin",0,64
incbin "../img/tile4.bin",0,64
incbin "../img/tile5.bin",0,64
incbin "../img/tile6.bin",0,64

endtilesgraphics:


spritesgraphics:
spritedatamonigote:

incbin	"../img/jugador-spritesheet-izq.bin",0,1152
incbin	"../img/jugador-spritesheet.bin",0,1152

spritedatamona:
incbin	"../img/mona-alta-8x32.bin",0,128

spritedatamonochico:
incbin "../img/mono-comp-8x16.bin", 0, 64

spritedatamonogrande:
incbin "../img/enemigo-grande.bin", 0, 256

endspritesgraphics:

section .bss
  ; uninitialized data

memorialibre:
