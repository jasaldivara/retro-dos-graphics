
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

  mSetVideoMode 4	; CGA 4 Colores 320 x 200

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
  mov ax, [spritey]
  mov bx, [spritex]
  mov dx, spritemonigote
  call dibujasprite16

  call readjoystickpos

  .cmplx:
  .cmplx1:
  mov ax, [js1xcount]
  mov bx, [js1xtb1]

  cmp ax, bx
  jge .cmplx2

  .lx1:
  mov dx, [spritex]
  dec dx
  dec dx
  dec dx
  mov [spritenx], dx
  jmp .cmply

  .cmplx2:
  mov ax, [js1xcount]
  mov bx, [js1xtb2]

  cmp ax, bx
  jge .cmplx3

  .lx2:
  mov dx, [spritex]
  dec dx
  dec dx
  mov [spritenx], dx
  jmp .cmply

  .cmplx3:
  mov ax, [js1xcount]
  mov bx, [js1xtb3]

  cmp ax, bx
  jge .cmpgx

  .lx3:
  mov dx, [spritex]
  dec dx
  mov [spritenx], dx
  jmp .cmply

  .cmpgx:
  .cmpgx3:
  mov bx, [js1xte3]
  cmp ax, bx
  jle .cmpgx2

  .gx3:
  mov dx, [spritex]
  inc dx
  inc dx
  inc dx
  mov [spritenx], dx
  jmp .cmply

  .cmpgx2:
  mov bx, [js1xte2]
  cmp ax, bx
  jle .cmpgx1

  .gx2:
  mov dx, [spritex]
  inc dx
  inc dx
  mov [spritenx], dx
  jmp .cmply

  .cmpgx1:
  mov bx, [js1xte1]
  cmp ax, bx
  jle .cmply

  .gx1:
  mov dx, [spritex]
  inc dx
  mov [spritenx], dx
  ; jmp .cmply


  .cmply:
  .cmply1:
  mov ax, [js1ycount]
  mov bx, [js1ytb1]

  cmp ax, bx
  jge .cmply2

  .ly1:
  mov dx, [spritey]
  dec dx
  dec dx
  dec dx
  mov [spriteny], dx
  jmp .cmpend

  .cmply2:
  mov ax, [js1ycount]
  mov bx, [js1ytb2]

  cmp ax, bx
  jge .cmply3

  .ly2:
  mov dx, [spritey]
  dec dx
  dec dx
  mov [spriteny], dx
  jmp .cmpend

  .cmply3:
  mov ax, [js1ycount]
  mov bx, [js1ytb3]

  cmp ax, bx
  jge .cmpgy

  .ly3:
  mov dx, [spritey]
  dec dx
  mov [spriteny], dx
  jmp .cmpend

  .cmpgy:
  .cmpgy3:
  mov bx, [js1yte3]
  cmp ax, bx
  jle .cmpgy2

  .gy3:
  mov dx, [spritey]
  inc dx
  inc dx
  inc dx
  mov [spriteny], dx
  jmp .cmpend

  .cmpgy2:
  mov bx, [js1yte2]
  cmp ax, bx
  jle .cmpgy1

  .gy2:
  mov dx, [spritey]
  inc dx
  inc dx
  mov [spriteny], dx
  jmp .cmpend

  .cmpgy1:
  mov bx, [js1yte1]
  cmp ax, bx
  jle .cmpend

  .gy1:
  mov dx, [spritey]
  inc dx
  mov [spriteny], dx
  .cmpend:

  ; Revisar que no se salga de los limites de la pantalla
  .xlim:
  mov ax, [spritenx]
  cmp ax, 0
  jge .sigxlim
  xor ax, ax
  mov [spritenx], ax
  jmp .ylim
  .sigxlim:
  cmp ax, 320 - 16
  jle .ylim
  mov ax, 320 - 16
  mov [spritenx], ax

  .ylim:
  mov ax, [spriteny]
  cmp ax, 0
  jge .sigylim
  xor ax, ax
  mov [spriteny], ax
  jmp .limend
  .sigylim:
  cmp ax, (200d - 16d)
  jle .limend
  mov ax, (200d - 16d)
  mov [spriteny], ax
  .limend:



  VSync

  .borrasprite:
  mov ax, [spritey]
  mov bx, [spritex]
  call borrasprite16

  .actualizacoord:
  mov ax, [spriteny]
  mov [spritey], ax

  mov ax, [spritenx]
  mov [spritex], ax

  jmp .ciclo


dibujasprite16:
  ; Parametros:
  ; AX = Coordenada Y
  ; BX = Coordenada X
  ; DX = Mapa de bits

  ; -1.- Revisar si pixeles están alineados con bytes
  test bx, 00000011b
  jnz dibujasprite16noalineado
  shr bx, 1
  shr bx, 1

  ; 0.- Respaldar cosas que deberíamos consevar

  mov si, dx  ; Cargar direccion de mapa de bits

  ; 1.- Seleccionar banco de memoria

  mov cx, MEMCGAEVEN
  mov es, cx
  mov cx, ax  ; Copiar / respaldar coordenada Y
  shr ax, 1 ; Descartar el bit de selección de banco

  ; 2.- Multiplicar
  mov dl, 80d
  mul dl    ; multiplicar por ancho de pantalla en bytes
  add ax, bx  ; Desplazamiento del byte que vamos a manipular
  mov di, ax

  ; 3.- En caso de que coordenada Y sea impar, comenzar a dibujar sprite desde
  ; la segunda fila de pixeles del mapa de bits en coordenada par de pantalla.
  test cx, 00000001b
  jz .espar
  add si, 4
  add di, 80d
  .espar pushf

  mov cx, 8  ; 4 .- Primero dibujamos 8 renglones (en renglones par de patalla)

  .looprenglon:

  ;movsw
  ;movsw
  lodsw
  stosw
  lodsw
  stosw

  add di, 76d ; Agregar suficientes bytes para que sea siguiente renglon
  add si, 4 ; Saltar renglones de ssprite.mapa de bits
  loop .looprenglon

  ; 5 .- Después dibujamos otros 8 renglones de sprite, ahora en renglones impar de pantalla

  mov cx, MEMCGAODD ; Dibujar en renglones impar de pantalla CGA 4 Col
  mov es, cx

  sub di, 640d  ; Retroceder hasta posicion inicial en pantalla ? (pero ahora en renglon impar)
  sub si, 60d   ; retrocedemos hasta posicion inicial de sprite ?

  popf ; ¿Necesario?
  jz .espar2
  sub si, 8
  sub di, 80d
  .espar2:

  mov cx, 8

  .looprenglon2:

  movsw
  movsw

  add di, 76d ; Agregar suficientes bytes para que sea siguiente renglon
  add si, 4 ; Saltar renglones de ssprite.mapa de bits
  loop .looprenglon2

  ret

dibujasprite16noalineado:

  ; 0.- Respaldar cosas que deberíamos consevar

  mov si, dx  ; Cargar direccion de mapa de bits

  ; 1.- Seleccionar banco de memoria

  mov cx, MEMCGAEVEN
  mov es, cx
  mov cx, ax  ; Copiar / respaldar coordenada Y
  shr ax, 1 ; Descartar el bit de selección de banco

  ; 2.- Multiplicar
  mov dl, 80d
  mul dl    ; multiplicar por ancho de pantalla en bytes
  mov dx, bx  ; Copiar coordenada X
  shr dx, 1   ; Descartar dos ultimos bits
  shr dx, 1
  add ax, dx  ; Desplazamiento del byte que vamos a manipular
  mov di, ax
  and bx, 00000011b	; Usar solo ultimos dos bits para posicion sub-byte

  ; 3.- En caso de que coordenada Y sea impar, comenzar a dibujar sprite desde
  ; la segunda fila de pixeles del mapa de bits en coordenada par de pantalla.
  test cx, 00000001b
  jz .espar
  add si, 4
  add di, 80d
  .espar pushf

  mov cx, 8  ; 4 .- Primero dibujamos 8 renglones (en renglones par de patalla)


  .looprenglon:

  push cx ; guardar contador de renglones

  mov dx, bx     ; copiar coordenada subpixel
  shl dx, 1	; Multiplicar c-subpixel por 2 (2 bits por pixel)
  mov cx, dx    ; guardar bits a desplazar en el contador

  xor ax, ax	; borrar ax

  lodsb         ; cargar byte en al
  shr ax, cl    ; desplazar esa cantidad de bits
  stosb		; Escribir byte (?)

  dec si
  lodsw
  xchg ah, al
  mov cx, dx
  shr ax, cl    ; desplazar esa cantidad de bits
  stosb		; Escribir byte (?)

  dec si
  lodsw
  xchg ah, al
  mov cx, dx
  shr ax, cl    ; desplazar esa cantidad de bits
  stosb		; Escribir byte (?)

  dec si
  lodsw
  xchg ah, al
  mov cx, dx
  shr ax, cl    ; desplazar esa cantidad de bits
  stosb		; Escribir byte (?)

  xor ax, ax
  mov ah, [ds:si - 1]
  mov cx, dx
  shr ax, cl
  stosb

  ; movsw	-- Descartar estos
  ; movsw

  add di, 75d ; Agregar suficientes bytes para que sea siguiente renglon
  add si, 4 ; Saltar renglones de sprite.mapa de bits

  pop cx  ; contador de renglones
  loop .looprenglon

  ;popf	; Salir por mientras
  ;ret
  ; 5 .- Después dibujamos otros 8 renglones de sprite, ahora en renglones impar de pantalla

  mov cx, MEMCGAODD ; Dibujar en renglones impar de pantalla CGA 4 Col
  mov es, cx

  sub di, 640d  ; Retroceder hasta posicion inicial en pantalla ? (pero ahora en renglon impar)
  sub si, 60d   ; retrocedemos hasta posicion inicial de sprite ?

  popf ; ¿Necesario?
  jz .espar2
  sub si, 8
  sub di, 80d
  .espar2:

  mov cx, 8

  .looprenglon2:

  push cx ; guardar contador de renglones

  mov dx, bx     ; copiar coordenada subpixel
  shl dx, 1	; Multiplicar c-subpixel por 2 (2 bits por pixel)
  mov cx, dx    ; guardar bits a desplazar en el contador

  xor ax, ax	; borrar ax

  lodsb         ; cargar byte en al
  shr ax, cl    ; desplazar esa cantidad de bits
  stosb		; Escribir byte (?)

  dec si
  lodsw
  xchg ah, al
  mov cx, dx
  shr ax, cl    ; desplazar esa cantidad de bits
  stosb		; Escribir byte (?)

  dec si
  lodsw
  xchg ah, al
  mov cx, dx
  shr ax, cl    ; desplazar esa cantidad de bits
  stosb		; Escribir byte (?)

  dec si
  lodsw
  xchg ah, al
  mov cx, dx
  shr ax, cl    ; desplazar esa cantidad de bits
  stosb		; Escribir byte (?)

  xor ax, ax
  mov ah, [ds:si - 1]
  mov cx, dx
  shr ax, cl
  stosb


  add di, 75d ; Agregar suficientes bytes para que sea siguiente renglon
  add si, 4 ; Saltar renglones de ssprite.mapa de bits
  pop cx  ; contador de renglones
  loop .looprenglon2


  ; Fin. Retornar
  ret

borrasprite16:

  ; Parametros:
  ; AX = Coordenada Y
  ; BX = Coordenada X


  ; 0.- Respaldar cosas que deberíamos consevar

  ; 1.- Seleccionar banco de memoria

  mov cx, MEMCGAEVEN
  mov es, cx
  mov cx, ax  ; Copiar / respaldar coordenada Y
  shr ax, 1 ; Descartar el bit de selección de banco

  ; Multiplicar
  mov dl, 80d
  mul dl    ; multiplicar por ancho de pantalla en bytes
  shr bx, 1
  shr bx, 1
  add ax, bx  ; Desplazamiento del byte que vamos a manipular
  mov di, ax

  ; En caso de que coordenada Y sea impar, comenzar a dibujar sprite desde
  ; la segunda fila de pixeles del mapa de bits en coordenada par de pantalla.
  test cx, 00000001b
  jz .espar
  add di, 80d
  .espar pushf

  mov cx, 8  ; Primero dibujamos 8 renglones (en renglones par de patalla)
  xor ax, ax  ; Registro AX en ceros

  .looprenglon:

  stosw
  stosw
  stosb

  add di, 75d ; Agregar suficientes bytes para que sea siguiente renglon
  loop .looprenglon

  ; Después dibujamos otros 8 renglones de sprite, ahora en renglones impar de pantalla

  mov cx, MEMCGAODD ; Dibujar en renglones impar de pantalla CGA 4 Col
  mov es, cx

  sub di, 640d  ; Retroceder hasta posicion inicial en pantalla ? (pero ahora en renglon impar)

  popf ; ¿Necesario?
  jz .espar2
  sub di, 80d
  .espar2:

  mov cx, 8

  .looprenglon2:

  stosw
  stosw
  stosb

  add di, 75d ; Agregar suficientes bytes para que sea siguiente renglon
  loop .looprenglon2

  ret



calculalimites:

  ; Calcular en X

  mov ax, [js1xbegin]
  mov bx, [js1xcenter]
  mov cx, ax
  add cx, bx
  shr cx, 1
  mov [js1xtb2], cx
  add ax, cx
  shr ax, 1
  mov [js1xtb1], ax
  mov ax, bx
  add ax, cx
  shr ax, 1
  mov [js1xtb3], ax

  mov ax, [js1xend]
  mov cx, ax
  add cx, bx
  shr cx, 1
  mov [js1xte2], cx
  add bx, cx
  shr bx, 1
  mov [js1xte1], bx
  add ax, cx
  shr ax, 1
  mov [js1xte3], ax


  ; Calcular en Y

  mov ax, [js1ybegin]
  mov bx, [js1ycenter]
  mov cx, ax
  add cx, bx
  shr cx, 1
  mov [js1ytb2], cx
  add ax, cx
  shr ax, 1
  mov [js1ytb1], ax
  mov ax, bx
  add ax, cx
  shr ax, 1
  mov [js1ytb3], ax

  mov ax, [js1yend]
  mov cx, ax
  add cx, bx
  shr cx, 1
  mov [js1yte2], cx
  add bx, cx
  shr bx, 1
  mov [js1yte1], bx
  add ax, cx
  shr ax, 1
  mov [js1yte3], ax

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

spritex:    dw 40d
spritey:    dw 10d
spritenx:    dw 40d
spriteny:    dw 10d


  ; program data

js2ycount:	dw 0000h
js2xcount:	dw 0000h
js1ycount:	dw 0000h
js1xcount:	dw 0000h

  ; Joystick calibration

js1xbegin:   dw 1d
js1xtb1:      dw 5d
js1xtb2:      dw 10d
js1xtb3:      dw 15d
js1xcenter:  dw 20d
js1xte1:      dw 25d
js1xte2:      dw 30d
js1xte3:      dw 35d
js1xend:     dw 40d

js1ybegin:   dw 1d
js1ytb1:      dw 5d
js1ytb2:      dw 10d
js1ytb3:      dw 15d
js1ycenter:  dw 20d
js1yte1:      dw 25d
js1yte2:      dw 30d
js1yte3:      dw 35d
js1yend:     dw 40d

msgcalibra: db 'Calibracion de Joystick', 0x00
msgsuelte: db 'Suelte el boton A del Joytick', 0x00
msgjbegin:     db 'Mantenga su joystick en la posicion Arriba e Izquierda y presione el boton A', 0x00   ; message
msgjcenter:     db 'Mantenga su joystick en posicion Centrado y presione el boton A', 0x00   ; message
msgjend:     db 'Mantenga su joystick en posicion Abajo y a la Derecha y presione el boton A', 0x00   ; message


; Sprite bitmaps
align   8,db 0


spritemonigote:
incbin	"moni",0,64
