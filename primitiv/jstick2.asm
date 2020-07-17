
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

	%%Retrace2:				;	IN	AL,DX
	IN	AL,DX		; AL := Port[03DAH]
	TEST	AL,8			; Is bit 3 unset?
	JNZ	%%Retrace2		; No, continue waiting

  %%Retrace1:
	IN	AL,DX			; AL := Port[03DAH]
	TEST	AL,8			; Is bit 3 set?
	JZ	%%Retrace1		; No, continue waiting


  %endmacro

  %macro mSetVideoMode 1

  mov  ah, 0   ; Establecer modo de video
  mov  al, %1      ; Modo de video
  int  10h   ; LLamar a la BIOS para servicios de video

  %endmacro

  %macro EsperaTiempo 0

  call esperatiempo

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


org 100h

section .text

start:


  mSetVideoMode 3	; CGA Modo 3: Texto a color, 80 x 25.

  ; Disable blinking
  mov dx, 03D8h
  mov al, 00001001b
  out dx, al

  EsperaTiempo

  lea bx, [msgcalibra]
  mEscribeStringzColor  00001111b, 2, 1

  EsperaTiempo

  lea bx, [msgjbegin]
  mEscribeStringzColor  00001111b, 2, 3

  call ciclomuestrajoystick

  call readjoystickpos

  mov ax, [js1ycount]
  mov [js1ybegin], ax

  mov ax, [js1xcount]
  mov [js1xbegin], ax

  EsperaTiempo

  lea bx, [msgsuelte]
  mEscribeStringzColor  00001111b, 2, 9

  mBorraTexto 80d, 0, 3

  call esperajoystick

  EsperaTiempo

  lea bx, [msgjcenter]
  mEscribeStringzColor  00001111b, 2, 3

  mBorraTexto 80d, 0, 9

  call ciclomuestrajoystick

  call readjoystickpos

  mov ax, [js1ycount]
  mov [js1ycenter], ax

  mov ax, [js1xcount]
  mov [js1xcenter], ax

  EsperaTiempo

  lea bx, [msgsuelte]
  mEscribeStringzColor  00001111b, 2, 9

  mBorraTexto 80d, 0, 3

  call esperajoystick

  EsperaTiempo

  lea bx, [msgjend]
  mEscribeStringzColor  00001111b, 2, 3

  mBorraTexto 80d, 0, 9

  call ciclomuestrajoystick

  call readjoystickpos

  mov ax, [js1ycount]
  mov [js1yend], ax

  mov ax, [js1xcount]
  mov [js1xend], ax

  EsperaTiempo

  lea bx, [msgsuelte]
  mEscribeStringzColor  00001111b, 2, 9

  mBorraTexto 80d, 0, 3

  call esperajoystick

  EsperaTiempo

  call calculalimites

  call juego

fin:
  ; 2 .- Salir al sistema

  mSetVideoMode 3	; CGA Modo 3: Texto a color, 80 x 25.
  
  int 20h

juego:

  mSetVideoMode 3	; CGA Modo 3: Texto a color, 80 x 25.

  .ciclo:

  .readkeyboard:
  mov ah, 1
  int 16h
  jz .continua

  mov ah, 0
  int 16h
  cmp ah, KB_ESC  ; Comprobar si es tecla ESC
  jne .continua

  ret
  .continua:

  .drawsprite:
  mov dh, [spritey]
  mov dl, [spritex]
  mov bh, 00001001b
  mov bl, 2   ; 2 = cara de color relleno en IBM ASCII
  call escribecaracter

  call readjoystickpos

  .cmplx:
  mov ax, [js1xcount]
  mov bx, [js1xt1]

  cmp ax, bx
  jge .cmpgx

  .lx:
  mov dl, [spritex]
  dec dl
  mov [spritenx], dl
  jmp .cmply

  .cmpgx:
  mov bx, [js1xt2]
  cmp ax, bx
  jle .cmply

  .gx:
  mov dl, [spritex]
  inc dl
  mov [spritenx], dl

  .cmply:
  mov ax, [js1ycount]
  mov bx, [js1yt1]

  cmp ax, bx
  jge .cmpgy

  .ly:
  mov dl, [spritey]
  dec dl
  mov [spriteny], dl
  jmp .cmpend

  .cmpgy:
  mov bx, [js1yt2]
  cmp ax, bx
  jle .cmpend

  .gy:
  mov dl, [spritey]
  inc dl
  mov [spriteny], dl
  .cmpend:

  VSync
  VSync

  .borrasprite:
  mov dh, [spritey]
  mov dl, [spritex]
  mov cx, 1
  call borratexto

  .actualizacoord:
  mov al, [spriteny]
  mov [spritey], al

  mov al, [spritenx]
  mov [spritex], al

  jmp .ciclo

calculalimites:

  ; Calcular en X

  mov ax, [js1xbegin]
  mov bx, [js1xcenter]
  add ax, bx
  shr ax, 1
  mov [js1xt1], ax
  mov ax, [js1xend]
  add ax, bx
  shr ax, 1
  mov [js1xt2], ax

  ; Calcular en Y

  mov ax, [js1ybegin]
  mov bx, [js1ycenter]
  add ax, bx
  shr ax, 1
  mov [js1yt1], ax
  mov ax, [js1yend]
  add ax, bx
  shr ax, 1
  mov [js1yt2], ax

ret

ciclomuestrajoystick:

  .mainloop:

  readJoystick

  push ax

  test al, JS1A

  jnz .noa

  pop ax

  ret

  mov bh, 00001011b
  mov bl, 'A'

  jmp .escribea

  .noa:

  mov bh, 00001111b
  mov bl, 0

  .escribea:

  mov dh, 5
  mov dl, 6
  call escribecaracter

  .sig1:

  pop ax

  test al, JS1B
  jnz .nob

  mov bh, 00001011b
  mov bl, 'B'
  mov dh, 5
  mov dl, 8
  call escribecaracter

  jmp .sig2

  .nob:

  mov bh, 00001111b
  mov bl, 0
  mov dh, 5
  mov dl, 8
  call escribecaracter

  .sig2:

  call readjoystickpos

  mov bx, [js1ycount]
  mov dh, 5
  mov dl, 15
  call escribepalabradecimal

  mov bx, [js1xcount]
  mov dh, 5
  mov dl, 22
  call escribepalabradecimal

  VSync

  jmp .mainloop

  .return:

  ret

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

esperajoystick:

  .preloop:

  mov cx, 9

  .loop:

  readJoystick

  test al, JS1A

  jz .preloop

  VSync

  loop .loop

  ret

esperatiempo:


  .preloop:

  mov cx, 18

  .loop:

  VSync

  loop .loop

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

borratexto:
  ; cx = Cantidad de caracteres a borrar
  ; dh = coord y
  ; dl = coord x

  mov ax, cs	; Use code segment in .com executable, because is the same as data segment
  mov ds, ax

  mov ax, MEMCGAEVEN
  mov es, ax


  mov al, BYTESPERROW
  mul dh
  xor dh, dh
  shl dx, 1	; multiplicar x * 2
  add ax, dx
  mov di, ax	; Destino en pantalla en es:di

  xor ax, ax

  rep stosw

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

  ; variables del "juego"

spritex:    db 40d
spritey:    db 10d
spritenx:    db 40d
spriteny:    db 10d


  ; program data

js2ycount:	dw 0000h
js2xcount:	dw 0000h
js1ycount:	dw 0000h
js1xcount:	dw 0000h

  ; Joystick calibration

js1xbegin:   dw 1d
js1xt1:      dw 10d
js1xcenter:  dw 20d
js1xt2:      dw 30d
js1xend:     dw 40d

js1ybegin:   dw 1d
js1yt1:      dw 10d
js1ycenter:  dw 20d
js1yt2:      dw 30d
js1yend:     dw 40d

msgcalibra: db 'Calibracion de Joystick', 0x00
msgsuelte: db 'Suelte el boton A del Joytick', 0x00
msgjbegin:     db 'Mantenga su joystick en la posicion Arriba e Izquierda y presione el boton A', 0x00   ; message
msgjcenter:     db 'Mantenga su joystick en posicion Centrado y presione el boton A', 0x00   ; message
msgjend:     db 'Mantenga su joystick en posicion Abajo y a la Derecha y presione el boton A', 0x00   ; message

