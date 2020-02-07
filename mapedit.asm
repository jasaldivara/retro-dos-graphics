
CPU 8086


  %define MEMCGAEVEN 0xB800
  %define MEMCGAODD 0xBA00

  %define KB_ESC 01
  %define KB_UP 48h
  %define KB_DOWN 50h
  %define KB_LEFT 4Bh
  %define KB_RIGHT 4Dh

  %define BYTESPERROW 160d

  ; Estructuras de datos

  struc DTA	; Disk Transfer Area

    .privado:	resb 21
    .attrib:	resb 1
    .time:	resw 1
    .date:	resw 1
    .filesize:	resd 1
    .filename:	resb 13

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

  %macro SetDta 1

  mov dx, %1
  mov ah, 1ah
  int 21h

  %endmacro

  %macro mSetVideoMode 1

  mov  ah, 0   ; Establecer modo de video
  mov  al, %1      ; Modo de video
  int  10h   ; LLamar a la BIOS para servicios de video

  %endmacro

  %macro mEscribeStringzColor 3

  ; ds:bx = stringz
  ; %1 = atributos (colores)
  ; %2 = x
  ; %3 = y

  mov dh, %2
  mov dl, %3
  mov ch, %1
  call escribestringz

  %endmacro

  %macro mDibujaCuadroDoble	5
  ; %1 = Atributos (colores)
  ; %2 = x
  ; %3 = y
  ; %4 = w
  ; %5 = h

  mov ch, %1
  mov dh, %2
  mov dl, %3
  mov bh, %4
  mov bl, %5
  call cuadrodoble

  %endmacro

  %macro mGetCurrentDir 1-2 0
  ; %1 = buffer donde escribir el directorio
  ; %2 = Numero de disco (default = 0)

  mov si, %1
  mov dl, %2
  mov ah, 47h	; MSDOS: Current Dir
  int 21h	; Llamada al sistema MSDOS

  %endmacro

  org 100h

section .text

start:

  SetDta midta

  mSetVideoMode 3	; CGA Modo 3: Texto a color, 80 x 25.

  ; Dibujar cuadro doble en pantalla

  mDibujaCuadroDoble 00011111b, 2, 4, 60, 16

  ; Escribir texto en pantalla

  lea bx, [msg1]
  mEscribeStringzColor  00011111b, 2, 6

  mGetCurrentDir buffer	; Obtener ruta del directorio actuañ

  ; mostrar directorio actual
  jc .err1
  lea bx, [buffer]
  jmp .escribe
  .err1:
  lea bx, [msgerror]
  .escribe:
  mEscribeStringzColor  01011111b, 10, 18



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

pdta:	resw 1	; Puntero a DTA actual (en caso de que no se pueda establecer uno nuevo

buffer:         resb    64

midta:		resb	DTA_size

