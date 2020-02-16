
CPU 8086


  %define MEMCGAEVEN 0xB800
  %define MEMCGAODD 0xBA00

  %define KB_ESC 01
  %define KB_UP 48h
  %define KB_DOWN 50h
  %define KB_LEFT 4Bh
  %define KB_RIGHT 4Dh

  %define BYTESPERROW 160d

  %define SHOWDIRS 00010000b

  ; Estructuras de datos

  struc DTA	; Disk Transfer Area

    .privado:	resb 21
    .attrib:	resb 1
    .time:	resw 1
    .date:	resw 1
    .filesize:	resd 1
    .filename:	resb 13

  endstruc

  struc FILENAME

    .attrib	resb 1
    .filename	resb 13

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

  mov dh, %3
  mov dl, %2
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

  %macro SetDta 1

  mov dx, %1
  mov ah, 1ah	; MSDOS: SetDTA
  int 21h

  %endmacro

  %macro GetDTA	0
  ; Valores de retorno:
  ; ES:BX = Dirección de DTA

  mov ah, 2Fh	; MSDOS: GetDTA
  int 21h

  %endmacro

  %macro mGetCurrentDir 1-2 0
  ; %1 = buffer donde escribir el directorio
  ; %2 = Numero de disco (default = 0)

  mov si, %1
  mov dl, %2
  mov ah, 47h	; MSDOS: Current Dir
  int 21h	; Llamada al sistema MSDOS

  %endmacro

  %macro FindFirst 0-2 pathtodos, 00010000b
  ; %1 = ruta de archivo(s) a buscar
  ; %2 = atributos de busqueda
  ; Retorno:
  ; Carry set = error
  ;	ax = 2, ruta de búsqueda no válida
  ;	ax = 18, ningún archivo coincide
  ; Carry unset = todo bien
  ;	Infomación sobre archivo encontrado en DTA

  mov dx, %1
  mov cx, %2
  mov ah, 4Eh	; MSDOS: Find First
  int 21h	; Llamada al sistema MSDOS

  %endmacro

  %macro mSelectFile 0-5 00010000b, pathtodos, 10, 2, 2
  ; %1 = File attributes
  ; %2 = Pathname with wildcards
  ; %3 = Windowheight / files per window
  ; %4 = X coord
  ; %5 = Y coord

  push bp
  mov bp, sp

  ; meter parámetros en la pila en orden inverso
  ; push word %5	; Commenting this out because 8086 processor doesn't support pushing immediate operands
  ; push word %4
  ; push word %3
  ; push word %2
  ; push word %1
  sub sp, (5 * 2)  ; 5 parametros *  2 bytes cada palabra
  mov word [bp - 10], %1
  mov word [bp - 8], %2
  mov word [bp - 6], %3
  mov word [bp - 4], %4
  mov word [bp - 2], %5

  call selectfile

  ; eliminar parametros de la pila
  ;add sp, (5 * 2)	; 5 parametros *  2 bytes cada palabra
  mov sp, bp
  pop bp

  %endmacro

  %macro FindNext 0

  mov ah, 4Fh	; MSDOS: Find Next
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


  mGetCurrentDir buffer	; Obtener ruta del directorio actuañ

  ; mostrar directorio actual
  jc .err1
  lea bx, [buffer]
  jmp .escribe
  .err1:
  lea bx, [msgerror]
  .escribe:
  mEscribeStringzColor  00011111b, 6, 2

  mSelectFile SHOWDIRS, pathtodos, 15, 0, 2

  ; Listar archivos del directorio
  ; FindFirst

  ; mov cl, 3
  ; jc .sig
  ; .muestrarchivo:
  ; push ax
  ; GetDTA
  ; mov ax, es
  ; mov ds, ax
  ; add bx, DTA.filename

  ; mEscribeStringzColor  00011111b, 6, cl

  ; FindNext
  ; inc cl
  ; jnc .muestrarchivo

  .sig:

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

selectfile:

  ; prologue
  push bp	; save old base pointer value
  mov bp, sp
  sub sp, (2 * 2)	; Make room for two local vars
  push di	; save source and destination indexes
  push si

  ; parameters
  ; [bp + 12] => y coord
  ; [bp + 10] => x coord
  ; [bp + 8] => WindowHeight / Files per page
  ; [bp + 6] => Pathname with wildcards
  ; [bp + 4] => File attributes
  ; [bp + 2] => previous ip/return address in near call (if far function, this will take two words for saving cs:ip)
  ; [bp] => previous value of bp
  ; [bp + 2] => first local variable
  ; [bp + 4] => second local variable

  ; 1.- Draw Window
  mov dh, [bp + 12]
  mov dl, [bp + 10]
  mov bl, [bp + 8]
  mov bh, 40
  mov ch, 00111111b

  call cuadrodoble


  ; 2.- Traverse directory
  ; .findfirst:
  ; xchg dx, bx
  ; push cx
  ; mov cl, ch
  ; xor ch, ch
  ; mov ax, 4Eh	; MSDOS: Find First
  ; int 21
  ; pop cx

  .findfirst:
  mov cx, [bp + 4]	; File search atttributes
  mov dx, [bp + 6]	; File search path with wildcards
  mov ah, 4eh		; MSDOS FindFirst function
  int 21h

  mov dh, [bp + 12]	; y coordinate
  inc dh

  jnc .displayfilename	; Display file name if there is no error
  xor ax, ax		; Clear ax and return on error :/
  jmp .epilogue

  .displayfilename:
  GetDTA
  mov ax, es
  mov ds, ax
  add bx, DTA.filename

  mov dl, [bp + 12]
  inc dl
  ; mov dl, cl
  mov ch, 00111111b
  push dx
  call escribestringz
  pop dx

  .findnext:
  FindNext
  inc dh
  jnc .displayfilename

  .epilogue:

  pop si
  pop di
  mov sp, bp
  pop bp
  ret

section .data
  ; program data

msg1:     db 'Probando cadena de texto', 0x00   ; message

msgerror:     db 'Probando cadena de texto', 0x00   ; message

enoarchivos:	db 'Error: No se encontraron archivos', 0
erutaincorrecta:	db 'Error: Ruta de archivos incorrecta', 0
eunknown:	db 'Error: Desconocido', 0

pathtodos:	db '*.*', 0x00	; encontrar todos los archivos

section .bss

pdta:	resw 1	; Puntero a DTA actual (en caso de que no se pueda establecer uno nuevo

buffer:         resb    64

midta:		resb	DTA_size



listfiles:	resb    (25 * FILENAME_size)



