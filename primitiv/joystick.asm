
CPU 8086


  %define MEMCGAEVEN 0xB800
  %define MEMCGAODD 0xBA00

  %define KB_ESC 01
  %define KB_UP 48h
  %define KB_DOWN 50h
  %define KB_LEFT 4Bh
  %define KB_RIGHT 4Dh

  %define BYTESPERROW	160d


  %define JOYSTICKPORT	201h
  %define JS2B	10000000b
  %define JS2A	01000000b
  %define JS1B	00100000b
  %define JS1A	00010000b
  %define JS2Y	00001000b
  %define JS2X	00000100b
  %define JS1Y	00000010b
  %define JS1X	00000001b

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

  %macro readJoystick 0

  mov dx, JOYSTICKPORT
  in al, dx

  %endmacro


org 100h

section .text

start:


  mSetVideoMode 3	; CGA Modo 3: Texto a color, 80 x 25.

  ; Disable blinking
  mov dx, 03D8h
  mov al, 00001001b
  out dx, al

  lea bx, [msg1]
  mEscribeStringzColor  00001111b, 6, 2

  ; jmp fin

  .mainloop:

  .readkeyb:
  mov ah, 1
  int 16h
  jz .nohaytecla

  mov ah, 0
  int 16h
  cmp ah, KB_ESC  ; Comprobar si es tecla ESC
  je fin

  .nohaytecla:

  readJoystick

  push ax
  test al, JS1A
  jnz .noa

  mov bh, 00001011b
  mov bl, 'A'
  mov dh, 4
  mov dl, 6
  call escribecaracter

  jmp .sig1

  .noa:

  mov bh, 00001111b
  mov bl, 0
  mov dh, 4
  mov dl, 6
  call escribecaracter

  .sig1:
  pop ax

  test al, JS1B
  jnz .nob

  mov bh, 00001011b
  mov bl, 'B'
  mov dh, 4
  mov dl, 8
  call escribecaracter

  jmp .sig2

  .nob:

  mov bh, 00001111b
  mov bl, 0
  mov dh, 4
  mov dl, 8
  call escribecaracter

  .sig2:

  call readjoystickpos

  mov bx, [js1ycount]
  mov dh, 4
  mov dl, 15
  call escribepalabradecimal

  mov bx, [js1xcount]
  mov dh, 4
  mov dl, 22
  call escribepalabradecimal

  VSync

  jmp .mainloop

fin:
  ; 2 .- Salir al sistema

  mSetVideoMode 3	; CGA Modo 3: Texto a color, 80 x 25.
  
  int 20h

readjoystickpos:

  xor ax, ax
  mov [js2ycount], ax
  mov [js2xcount], ax
  mov [js1ycount], ax
  mov [js1xcount], ax

  cli	; Deshabilitar interrupciones

  mov dx, JOYSTICKPORT
  out dx, al

  .jsloop:
  in al, dx

  test al, JS2Y
  jz .sig1
  inc word [js2ycount]

  .sig1:
  test al, JS2X
  jz .sig2
  inc word [js2xcount]

  .sig2:
  test al, JS1Y
  jz .sig3
  inc word [js1ycount]

  .sig3:
  test al, JS1X
  jz .sig4
  inc word [js1xcount]

  .sig4:
  test al, ( JS2Y | JS2X | JS1Y | JS1X )
  jnz .jsloop


  sti	; Habilitar interrupciones
  ret

escribepalabradecimal:
  ; bx = valor a escribir en pantalla
  ; dh = coord y
  ; dl = coord x

  mov cx, cs	; Use code segment in .com executable, because is the same as data segment
  mov ds, cx

  mov cx, MEMCGAEVEN
  mov es, cx


  mov al, BYTESPERROW
  mul dh
  xor dh, dh
  shl dx, 1	; multiplicar x * 2
  add ax, dx
  mov di, ax	; Destino en pantalla en es:di

  mov ax, bx
  mov cx, 5   ; 5 dígitos máximo
  std

  .ciclodigito:
  xor dx, dx
  mov bx, 10d
  div bx


  xchg ax, dx
  add al, '0'
  mov ah, 00001111b
  stosw
  mov ax, dx
  dec cx
  test ax, ax

  jnz .ciclodigito

  .cicloceros:
  cmp cx, 0
  jna .salir
  mov al, 0
  mov ah, 00001111b
  rep stosw

  .salir:
  cld
  ret

escribecaracter:
  ; bh = atributos / colores
  ; bl = caracter ascii
  ; dh = coord y
  ; dl = coord x

  mov cx, cs	; Use code segment in .com executable, because is the same as data segment
  mov ds, cx

  mov cx, MEMCGAEVEN
  mov es, cx


  mov al, BYTESPERROW
  mul dh
  xor dh, dh
  shl dx, 1	; multiplicar x * 2
  add ax, dx
  mov di, ax	; Destino en pantalla en es:di

  mov ax, bx

  stosw

  ret

escribestringz:
  ; escribe en pantalla cadena de caracteres terminada en cero
  ; bx = puntero a cadena
  ; dh = coord y
  ; dl = coord x
  ; ch = atributos/colores

  mov ax, cs	; Use code segment in .com executable, because is the same as data segment
  mov ds, ax

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


section .data
  ; program data

js2ycount:	dw 0000h
js2xcount:	dw 0000h
js1ycount:	dw 0000h
js1xcount:	dw 0000h

msg1:     db 'Botones y posici', 0A2h, 'n del Joystick', 0x00   ; message

