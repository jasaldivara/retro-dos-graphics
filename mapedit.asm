
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

  %define BYTESPERROW 160d

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
  mov dh, 5
  mov dl, 10
  mov ch, 00111111b
  call escribestringz

  mov dh, 6
  mov dl, 10
  mov bh, 40
  mov bl, 10
  mov ch, 01001111b
  call cuadrodoble

  ; Averiguar directorio actual
  mov ah, 47h
  mov dl, 0
  mov si, buffer
  int 21h

  ; mostrar directorio actual
  jc .err1
  lea bx, [buffer]
  jmp .escribe
  .err1:
  lea bx, [msgerror]
  .escribe:
  mov dh, 20
  mov dl, 10
  mov ch, 01011111b
  call escribestringz



fin:
  ; 2 .- Salir al sistema
  int 20h

escribecaracter:
  ; parametros
  ; bl = caracter
  ; bh = atributos/colores
  ; dh = coord y
  ; dl = coord x

  mov ax, MEMCGAEVEN
  mov es, ax

  mov al, BYTESPERROW
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
  ; dh = coord y
  ; dl = coord x
  ; ch = atributos/colores

  mov ax, MEMCGAEVEN
  mov es, ax

  mov si, bx	; cadena origen en si

  mov al, BYTESPERROW
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
  ret

cuadrodoble:
  ; Parametros:
  ; dh = coordenada y
  ; dl = coordenada x
  ; bh = ancho
  ; bl = alto
  ; ch = Atributos/colores

  mov ax, MEMCGAEVEN
  mov es, ax

  mov al, BYTESPERROW
  mul dh
  xor dh, dh
  shl dx, 1	; multiplicar x * 2
  add ax, dx
  mov di, ax	; Destino en pantalla en es:di

  ; esquina sup izquierda
  mov al, 201	; caracter de esquina izquierda doble
  mov ah, ch	; atributos
  stosw		; escribir

  ; linea horizontal superior
  mov al, 205	; caracter linea horizontal doble
  xor cx, cx
  mov cl, bh
  rep stosw

  ; esquina sup derecha
  mov al, 187	; caracter de esquina derecha doble
  stosw		; escribir

  ; lineas verticales y relleno
  xor cx, cx
  mov cl, bl

  ; aritmetica para dibujar en renglon siguiente
  xor dx, dx
  mov dl, bh
  inc dx
  inc dx
  shl dx, 1
  sub dx, BYTESPERROW
  sub di, dx

  .loopvertical:
  push cx

	  ; linea izquierda
	  mov al, 186	; caracter de linea vertical doble
	  stosw		; escribir

	  ; relleno
	  mov al, 0	; caracter linea horizontal doble
	  xor cx, cx
	  mov cl, bh
	  rep stosw

	  ; linea derecha
	  mov al, 186	; caracter de linea vertical doble
	  stosw		; escribir

	  ; adelantar al renglón siguiente
	  sub di, dx
  pop cx
  loop .loopvertical

  ; esquina inf izquierda
  mov al, 200	; caracter de esquina izquierda doble
  stosw		; escribir

  ; linea horizontal inferior
  mov al, 205	; caracter linea horizontal doble
  xor cx, cx
  mov cl, bh
  rep stosw

  ; esquina inf derecha
  mov al, 188	; caracter de esquina derecha doble
  stosw		; escribir


ret

section .data
  ; program data

msg1:     db 'Probando cadena de texto', 0x00   ; message

msgerror:     db 'Probando cadena de texto', 0x00   ; message



section .bss

buffer:         resb    64

