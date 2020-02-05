
CPU 8086

  %define VIDEOBIOS 0x10
  %define SETVIDEOMODE 0

  %define MEMCGAEVEN 0xB800
  %define MEMCGAODD 0xBA00

  %define KB_ESC 01
  %define KB_UP 48h
  %define KB_DOWN 50h
  %define KB_LEFT 4Bh
  %define KB_RIGHT 4Dh



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

  org 100h

section .text

start:

  ; 3 .- Establecer modo de video
  mov  ah, SETVIDEOMODE   ; Establecer modo de video
  mov  al, 3      ; CGA Modo 3: Texto a color, 80 x 25.
  int  VIDEOBIOS   ; LLamar a la BIOS para servicios de video


  mov bl, 'L'
  mov bh, 00011111b
  mov dh, 3
  mov dl, 0
  call escribecaracter

  mov bl, 'a'
  mov bh, 00011111b
  mov dh, 3
  mov dl, 1
  call escribecaracter

  mov bl, 'l'
  mov bh, 01001111b
  mov dh, 3
  mov dl, 2
  call escribecaracter

  mov bl, 'o'
  mov bh, 01001111b
  mov dh, 3
  mov dl, 3
  call escribecaracter

  lea bx, [msg1]
  mov dh, 10
  mov dl, 5
  mov ch, 00111111b
  call escribestringz

fin:
  ; 2 .- Salir al sistema
  int 20h

escribecaracter:
  ; parametros
  ; bl = caracter
  ; bh = atributos/colores
  ; dh = coord x
  ; dl = coord y

  mov ax, MEMCGAEVEN
  mov es, ax

  mov al, 160d
  mul dh
  xor dh, dh
  shl dx, 1	; multiplicar x * 2
  add ax, dx
  mov di, ax
  mov ax, bx
  stosw		; escribir caracter y atributos en memoria de video

  ret

escribestringz:
  ; escribe en pantalla cadena de caracteres terminada en cero
  ; bx = puntero a cadena
  ; dh = coord x
  ; dl = coord y
  ; ch = atributos/colores

  mov ax, MEMCGAEVEN
  mov es, ax

  mov si, bx	; cadena origen en si

  mov al, 160d
  mul dh
  xor dh, dh
  shl dx, 1	; multiplicar x * 2
  add ax, dx
  mov di, ax	; Destino en pantalla en es:di

  mov ah, ch	; atributos en byte alto

  .ciclo:
  lodsb		; Cargar caracter en al
  test al, al	; si es caracter es cero, terminar de escribir
  jz .fin
  ; mov ah, ch
  stosw		;  Escribir en pantalla, caracter + atributos
  jmp .ciclo

  .fin:


cuadrodoble:
  ; Parametros:
  ; bh = coordenada x
  ; bl = coordenada y
  ; dh = ancho
  ; dl = alto
  ; ah = Atributos/colores

ret

section .data
  ; program data

msg1:     db 'Probando cadena de texto', 0x00   ; message


