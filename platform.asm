
CPU 8086

  %define VIDEOBIOS 0x10
  %define SETVIDEOMODE 0
  %define CGA4COLOR 0x04
  %define WIDTHPX 320d
  %define HEIGHTPX 200d
  %define PXB 4   ; Pixeles por byte
  %assign PYTERPERSCAN (WIDTHPX * PXB)

  %define MEMCGAEVEN 0xB800
  %define MEMCGAODD 0xBA00

  %define KB_ESC 01
  %define KB_UP 48h
  %define KB_DOWN 50h
  %define KB_LEFT 4Bh
  %define KB_RIGHT 4Dh

  ; Constantes del juego

  %define GRAVEDAD 1
  %define REBOTEY 10
  %define ANCHO 16

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
  ; program code
  mov  ah, SETVIDEOMODE   ; Establecer modo de video
  mov  al, CGA4COLOR      ; CGA 4 Colores 320 x 200
  int  VIDEOBIOS   ; LLamar a la BIOS para servicios de video



  ; Dibujar sprite en su posicion inicial
  mov ax, [spritey]
  mov bx, [spritex]
  mov dx, spritemonigote
  call dibujasprite16

  frame:

  ; 1 .- Llamar a 'mecanicadeljuego' para que calcule posicion de sprites
  call mecanicadeljuego

  ; 2 .- VSync

  VSync

  ; 3 .- borrar
  mov ax, [spritey]
  mov bx, [spritex]
  call borrasprite16

  ; 4.- dibujar
  mov ax, [spriteny]
  mov bx, [spritenx]
  mov [spritey], ax
  mov [spritex], bx
  mov dx, spritemonigote
  call dibujasprite16

  ; repetir ciclo
  jmp frame

  leerteclado:
  ; 1.- Revisar teclado
  mov ah, 1   ; "Get keystroke status"
  int 16h
  jz .retorno

  mov ah, 0   ; Problema: Por alguna razon tengo que hacer lectura destructiva de teclado para que reporte la tecla presionada
  int 16h
  cmp ah, KB_ESC  ; Comprobar si es tecla ESC
  je fin
  cmp al, 'q'  ; Comprobar si es caracter 'q'
  je fin
  cmp al, 'Q'  ; Comprobar si es caracter 'Q'
  je fin
  cmp al, 'p'  ; Comprobar si es caracter 'p'
  je cambiapaleta
  cmp al, 'P'  ; Comprobar si es caracter 'P'
  je cambiapaleta
  cmp ah, KB_LEFT  ; Comprobar si es flecha izquierda
  je .movizq
  cmp ah, KB_RIGHT  ; Comprobar si es flecha derecha
  je .movder
  cmp ah, KB_UP  ; Comprobar si es flecha arriba
  je .saltar

  .retorno:
  ret

  .movizq
  mov ax, -1
  mov [deltax], ax
  ret

  .movder
  mov ax, 1
  mov [deltax], ax
  ret

  .saltar
  mov ax, [parado] ; Tiene que estar parado para poder saltar
  test ax, ax
  jz .noparado

  mov bx, 0 - REBOTEY
  mov [deltay], bx
  mov bx, 0
  mov [parado], bx

  .noparado
  ret

cambiapaleta:
  mov ah, [paleta]
  test ah, ah
  jz .sig
  mov bl, 0
  jmp .guarda
  .sig
  mov bl, 1
  .guarda
  mov [paleta], bl

  .llama_a_bios
  mov ah, 0Bx	; Establecer paleta de colores
  mov bh, 1	; Paleta de cuatro colores
  mov bl, [paleta]
  int  VIDEOBIOS
  ret


  mecanicadeljuego:

  ; 1.- Leer el teclado

  mov ax, 0
  mov [deltax], ax
  call leerteclado

  calcx:    ; 2.- calcular x

  mov ax, [spritex]
  mov bx, [deltax]
  add ax, bx

  ; 1.1.- revisar que no se salga

  cmp ax, WIDTHPX - ANCHO
  jng .sig1
  mov ax, WIDTHPX - ANCHO
  neg bx
  .sig1
  cmp ax, 0
  jnl .sig2
  mov ax, 0
  neg bx
  .sig2
  mov [spritenx], ax
  mov [deltax], bx

  calcdy:  ; 2.- Calcular delta Y
  mov dx, [deltay]
  add dx, GRAVEDAD
  mov [deltay], dx

  calcy:      ; 3.- calcular y
  
  mov ax, [spritey]
  mov bx, [deltay]
  add ax, bx

  ; 1.1.- revisar que no se salga

  cmp ax, HEIGHTPX - ANCHO
  jng .sig1
  mov ax, HEIGHTPX - ANCHO
  mov bx, 0
  mov word [parado], 1
  .sig1
  cmp ax, 0
  jnl .sig2
  mov ax, 0
  mov bx, 0
  .sig2
  mov [spriteny], ax
  mov [deltay], bx

  ; Fin de mecanica del juego
  ret
  
fin:
  int 20h



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
  .espar2

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
  .espar2

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
  .espar2

  mov cx, 8

  .looprenglon2:

  stosw
  stosw
  stosb

  add di, 75d ; Agregar suficientes bytes para que sea siguiente renglon
  loop .looprenglon2

  ret



section .data
  ; program data

  spritex:
  dw  40d
  spritey:
  dw 92d
  spritenx:
  dw  0
  spriteny:
  dw 0
  deltax:
  dw 0
  deltay:
  dw 0
  parado:
  dw 0
  paleta:
  db 1

  align   8,db 0

  spritepelota:
  db 00000000b, 00000000b, 00000000b, 00000000b
  db 00000000b, 00101010b, 10101010b, 00000000b
  db 00000000b, 10101010b, 10101010b, 10000000b
  db 00000010b, 10101010b, 10111011b, 10100000b
  db 00001010b, 10101010b, 10101110b, 10101000b
  db 00101010b, 10101010b, 10111011b, 10101010b
  db 00101010b, 10101010b, 10101010b, 10101010b
  db 00101010b, 10101010b, 10101010b, 10101010b
  db 00101010b, 10101010b, 10101010b, 10101010b
  db 00101010b, 01100110b, 10101010b, 10101010b
  db 00101001b, 10011001b, 10101010b, 10101010b
  db 00101010b, 01010110b, 10101010b, 10101010b
  db 00001001b, 10011001b, 10101010b, 10101000b
  db 00000010b, 01100110b, 10101010b, 10100000b
  db 00000000b, 10101010b, 10101010b, 10000000b
  db 00000000b, 00101010b, 10101010b, 00000000b

spritemonigote:
incbin	"moni",0,64

section .bss
  ; uninitialized data
