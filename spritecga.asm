
  %define VIDEOBIOS 0x10
  %define SETVIDEOMODE 0
  %define CGA4COLOR 0x04
  %define WIDTHPX 320d
  %define PXB 4   ; Pixeles por byte
  %assign PYTERPERSCAN (WIDTHPX * PXB)

  %define MEMCGAEVEN 0xB800
  %define MEMCGAODD 0xBA00

  %define KB_ESC 01
  %define KB_UP 48h
  %define KB_DOWN 50h
  %define KB_LEFT 4Bh
  %define KB_RIGHT 4Dh

  org 100h 
 
section .text 
 
start:
  ; program code
  mov  ah, SETVIDEOMODE   ; Establecer modo de video
  mov  al, CGA4COLOR      ; CGA 4 Colores 320 x 200
  int  VIDEOBIOS   ; LLamar a la BIOS para servicios de video



  mov ax, 10
  mov bx, 20
  mov dx, spritepelota
  call dibujasprite16

  ; Dibujar sprite en su posicion inicial
  mov ax, [spritey]
  mov bx, [spritex]
  mov dx, spritemonigote
  call dibujasprite16

  leerteclado:
  mov ah, 0
  int 16h
  cmp ah, KB_ESC  ; Comprobar si es tecla ESC
  je fin
  cmp ah, KB_UP
  je moverarriba
  cmp ah, KB_DOWN
  je moverabajo
  cmp ah, KB_LEFT
  je moverizquierda
  cmp ah, KB_RIGHT
  je moverderecha

  jmp leerteclado
  
fin:
  int 20h

  moverarriba:

  mov ax, [spritey]
  mov bx, [spritex]
  call borrasprite16
  mov ax, [spritey]
  dec ax
  mov [spritey], ax
  mov bx, [spritex]
  mov dx, spritemonigote
  call dibujasprite16
  jmp leerteclado

  moverabajo:

  mov ax, [spritey]
  mov bx, [spritex]
  call borrasprite16
  mov ax, [spritey]
  inc ax
  mov [spritey], ax
  mov bx, [spritex]
  mov dx, spritemonigote
  call dibujasprite16
  jmp leerteclado

  moverizquierda:

  mov ax, [spritey]
  mov bx, [spritex]
  call borrasprite16
  mov bx, [spritex]
  dec bx
  mov [spritex], bx
  mov ax, [spritey]
  mov dx, spritemonigote
  call dibujasprite16
  jmp leerteclado

  moverderecha:

  mov ax, [spritey]
  mov bx, [spritex]
  call borrasprite16
  mov bx, [spritex]
  inc bx
  mov [spritex], bx
  mov ax, [spritey]
  mov dx, spritemonigote
  call dibujasprite16
  jmp leerteclado


ponbyte:
  ; Parametros:
  ; ax: desplazamiento
  ; dl: Valor del byte
  mov di, ax
  mov ax, MEMCGAEVEN
  mov es, ax
  mov [es:di], dl
  ret

ponpixelcga4col:
  ; parametros:
  ; ax: coordenada Y
  ; bx: coordenada X
  ; ch: Color (2 bits)

  ; 1.- Seleccionar banco de memoria

  mov dx, MEMCGAEVEN
  test ax, 0000000000000001b
  jz .ponbanco
  mov dx, MEMCGAODD
  .ponbanco  mov es, dx

  ; 2.- Obtener dirección en memoria del byte a manipular

  shr ax, 1 ; Descartar el bit de selección de banco
  mov dl, 80d
  mul dl    ; multiplicar por ancho de pantalla en bytes
  mov dx, bx  ; Copiar a dx coordenada X
  shr dx, 1 ; Descartar ultimos dos bits de copia de coordenada X
  shr dx, 1 ; Descartar ultimos dos bits de copia de coordenada X
  add ax, dx  ; Desplazamiento del byte que vamos a manipular
  mov si, ax

  ; 3.- Obtener valor actual del byte a manipular

  mov dl, [es:si]

  ; 4.- borrar bits antes de sobreescribir

  and bx, 0000000000000011b   ; Tomar en cuenta sólo ultimos dos bits de coordenada X
  shl bx, 1                   ; Multiplicar por dos ultimo segmento de coord X
  mov cl, bl
  mov al, 11000000b   ; mascara de dos bits
  shr al, cl          ; ajustar mascara de bits
  not al              ; negativo de mascara
  and dl, al          ; Borrar sólo los bits correspondientes (mascara)

  ; 5.- Ajustar bits del pixel en byte
  mov bl, 6
  sub bl, cl
  mov cl, bl
  shl ch, cl

  ; 6.- Escribir bits correspondientes a pixel
  or dl, ch

  ; 7.- Reescribir byte en memoria de video
  mov [es:si], dl

  ; 8.- Fin
  ret

dibujasprite16:
  ; Parametros:
  ; AX = Coordenada Y
  ; BX = Coordenada X
  ; DX = Mapa de bits

  ; 0.- Respaldar cosas que deberíamos consevar

  mov si, dx  ; Cargar direccion de mapa de bits

  ; 1.- Seleccionar banco de memoria

  mov cx, MEMCGAEVEN
  mov es, cx
  mov cx, ax  ; Copiar / respaldar coordenada Y
  shr ax, 1 ; Descartar el bit de selección de banco

  ; Multiplicar
  mov dl, 80d
  mul dl    ; multiplicar por ancho de pantalla en bytes
  add ax, bx  ; Desplazamiento del byte que vamos a manipular
  mov di, ax

  ; En caso de que coordenada Y sea impar, comenzar a dibujar sprite desde
  ; la segunda fila de pixeles del mapa de bits en coordenada par de pantalla.
  test cx, 00000001b
  jz .espar
  add si, 4
  add di, 80d
  .espar pushf

  mov cx, 8  ; Primero dibujamos 8 renglones (en renglones par de patalla)

  .looprenglon:

  movsw
  movsw

  add di, 76d ; Agregar suficientes bytes para que sea siguiente renglon
  add si, 4 ; Saltar renglones de ssprite.mapa de bits
  loop .looprenglon

  ; Después dibujamos otros 8 renglones de sprite, ahora en renglones impar de pantalla

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

  add di, 76d ; Agregar suficientes bytes para que sea siguiente renglon
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

  add di, 76d ; Agregar suficientes bytes para que sea siguiente renglon
  loop .looprenglon2

  ret


esperatecla:

  wl:             ; mark wl
  mov ah,0        ; 0 - keyboard BIOS function to get keyboard scancode
  int 16h         ; keyboard interrupt
  jz wl           ; if 0 (no button pressed) jump to wl
  ret

section .data
  ; program data
 
  msg  db 'Hola amigos!!'
  crlf db 0x0d, 0x0a
  endstr db '$'

  spritex:
  dw  38d
  spritey:
  dw 92d

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

