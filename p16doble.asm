
CPU 8086

  %define VIDEOBIOS 0x10
  %define SETVIDEOMODE 0
  %define CGA6 0x06
  %define WIDTHPX 160d
  %define HEIGHTPX 100d
  %define PXB 2   ; Pixeles por byte
  %assign BYTESPERSCAN (WIDTHPX / PXB)

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
  %define ANCHOSPRITE 16
  %define ALTOSPRITE 16

  %define BWSPRITE ( ANCHOSPRITE / PXB )  ; Ancho de Sprite en Bytes

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

  ; 1 .- Guardar Rutina de interrupcion del teclado del sistema (BIOS)
  mov     al,9h
  mov     ah,35h
  int     21h
  mov [kb_int_old_off], bx
  mov [kb_int_old_seg], es

  ; 2 .- Registrar nueva rutina de interrupción del teclado
  mov     al, 9h
  mov     ah, 25h
  mov     bx, cs
  mov     ds, bx
  mov     dx, kb_int_new
  int     21h


  ; 3 .- Establecer modo de video
  mov  ah, SETVIDEOMODE   ; Establecer modo de video
  mov  al, CGA6      ; CGA Modo 6: monocromatico hi-res o composite lo-res
  int  VIDEOBIOS   ; LLamar a la BIOS para servicios de video

  ; 3.1 .- Entrar en modo de video compuesto
  mov dx, 03D8h
  mov al, 00011010b
  out dx, al


  ; 4 .- Dibujar sprite en su posicion inicial
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

  leerteclado_old:
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

  .movizq:
  mov ax, -1
  mov [deltax], ax
  ret

  .movder:
  mov ax, 1
  mov [deltax], ax
  ret

  .saltar:
  mov ax, [parado] ; Tiene que estar parado para poder saltar
  test ax, ax
  jz .noparado

  mov bx, 0 - REBOTEY
  mov [deltay], bx
  mov bx, 0
  mov [parado], bx

  .noparado:
  ret

leerteclado:

  mov al, [tecla_esc] ; ¿está presionada esta tecla?
  test al, al
  jnz fin

  mov al, [tecla_left] ; ¿está presionada esta tecla?
  test al, al
  jz .sig1

  .movizq:
  mov ax, -1
  mov [deltax], ax

  .sig1:
  mov al, [tecla_right] ; ¿está presionada esta tecla?
  test al, al
  jz .sig2

  .movder:
  mov ax, 1
  mov [deltax], ax

  .sig2:
  mov al, [tecla_up] ; ¿está presionada esta tecla?
  test al, al
  jz .sig3

  .saltar:
  mov ax, [parado] ; Tiene que estar parado para poder saltar
  test ax, ax
  jz .noparado

  mov bx, 0 - REBOTEY
  mov [deltay], bx
  mov bx, 0
  mov [parado], bx

  .noparado:


  .sig3:
  .retorno:
  ret




kb_int_new:
  ; Keyboard Interrupt Handler
  sti ; ??? ¿habilitar interrupciones?
  ; Guardar registros
  push ax
  push bx
  push cx
  push dx
  push si
  push di
  push ds
  push es


  mov ax, cs  ; Usar segemtno actual del programa, basado en cs
  mov ds, ax
  mov es, ax
  
  in al, 60h  ; obtener scancode
  mov bl, al  ; respaldarlo en otro registro

  in  al, 61h
  mov ah, al	;Save keyboard status
  or  al, 80h	;Disable
  out 61h, al
  mov al, ah	;Enable (If it was disabled at first, you wouldn't
  out 61h, al	; be doing this anyway :-)

  xchg ax, bx

  ; Revisar si es tecla presionada o liberada
  test al, 80h  ; Codigo de tecla liberada
  jnz .k_liberada

  .k_presionada:
  mov ah, 1 ; Valor 1 para tecla presionada

  jmp .cualtecla

  .k_liberada:
  and al, 7fh ; Conservar scancode de tecla, desechando bit de presionada o liberada
  mov ah, 0 ; valor 0 para tecla liberada

  .cualtecla:
  cmp al, KB_ESC
  jne .sig1
  mov bx, tecla_esc
  jmp .guardar
  .sig1:
  cmp al, KB_LEFT
  jne .sig2
  mov bx, tecla_left
  jmp .guardar
  .sig2:
  cmp al, KB_RIGHT
  jne .sig3
  mov bx, tecla_right
  jmp .guardar
  .sig3:
  cmp al, KB_UP
  jne .sig4
  mov bx, tecla_up
  jmp .guardar
  .sig4:



  jmp .salida
  
  .guardar:
  ;mov di, bx
  mov byte [bx], ah  ; Almacenar valor 1 ó 0 en registro de tecla correspondiente


  .salida:

  ;mov byte [tecla_esc], 11b
  cli ; ??? ¿Deshabilitar interrupciones

  ; Enviar señal EOI (End of Interrupt)
  mov     al,20h
  out     20h,al

  ; reestablecer registros
  pop es
  pop ds
  pop di
  pop si
  pop dx
  pop cx
  pop bx
  pop ax
  iret

cambiapaleta:
  mov ah, [paleta]
  test ah, ah
  jz .sig
  mov bl, 0
  jmp .guarda
  .sig:
  mov bl, 1
  .guarda:
  mov [paleta], bl

  .llama_a_bios:
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

  cmp ax, WIDTHPX - ANCHOSPRITE
  jng .sig1
  mov ax, WIDTHPX - ANCHOSPRITE
  neg bx
  .sig1:
  cmp ax, 0
  jnl .sig2
  mov ax, 0
  neg bx
  .sig2:
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

  cmp ax, HEIGHTPX - ( ALTOSPRITE * 2 )
  jng .sig1
  mov ax, HEIGHTPX - ( ALTOSPRITE * 2 )
  mov bx, 0
  mov word [parado], 1
  .sig1:
  cmp ax, 0
  jnl .sig2
  mov ax, 0
  mov bx, 0
  .sig2:
  mov [spriteny], ax
  mov [deltay], bx

  ; Fin de mecanica del juego
  ret
  
fin:
  ; 1 .- Reestablecer rutina original de manejo de teclado
  mov     dx,[kb_int_old_off]
  mov     ax,[kb_int_old_seg]
  mov     ds,ax
  mov     al,9h
  mov     ah,25h
  int     21h

  ; 2 .- Salir al sistema
  int 20h



dibujasprite16:
  ; Parametros:
  ; AX = Coordenada Y
  ; BX = Coordenada X
  ; DX = Mapa de bits

  ; -1.- Revisar si pixeles están alineados con bytes
  test bx, 0000001b
  jnz dibujasprite16noalineado
  shr bx, 1

  ; 0.- Respaldar cosas que deberíamos consevar

  mov si, dx  ; Cargar direccion de mapa de bits

  ; 1.- Seleccionar banco de memoria

  mov cx, MEMCGAEVEN
  mov es, cx
  ; mov cx, ax  ; Copiar / respaldar coordenada Y
  ; shr ax, 1 ; Descartar el bit de selección de banco

  ; 2.- Multiplicar
  mov dl, BYTESPERSCAN
  mul dl    ; multiplicar por ancho de pantalla en bytes
  add ax, bx  ; Desplazamiento del byte que vamos a manipular
  mov di, ax

  .dibujarenglones:

  mov cx, ALTOSPRITE  ; 4 .- Dibujamos TODOS los renglones (en renglones par de patalla)

  .looprenglon:

  movsw
  movsw
  movsw
  movsw


  add di, BYTESPERSCAN -  BWSPRITE; Agregar suficientes bytes para que sea siguiente renglon

  loop .looprenglon

  ; 5 .- Después dibujamos mismos renglones de sprite, ahora en renglones impar de pantalla

  mov cx, es
  cmp cx, MEMCGAODD
  je	.salir

  mov cx, MEMCGAODD ; Dibujar en renglones impar de pantalla CGA 4 Col
  mov es, cx

  sub di, BYTESPERSCAN * ALTOSPRITE  ; Retroceder hasta posicion inicial en pantalla ? (pero ahora en renglon impar)
  sub si, BWSPRITE * ( ALTOSPRITE )   ; retrocedemos hasta posicion inicial de sprite + un renglon

  jmp .dibujarenglones

	; retorno de la función
  .salir:
  ret

dibujasprite16noalineado:

  ; 0.- Respaldar cosas que deberíamos consevar

  mov si, dx  ; Cargar direccion de mapa de bits

  ; 1.- Seleccionar banco de memoria

  mov cx, MEMCGAEVEN
  mov es, cx
  mov cx, ax  ; Copiar / respaldar coordenada Y
  ; shr ax, 1 ; Descartar el bit de selección de banco

  ; 2.- Multiplicar
  mov dl, BYTESPERSCAN
  mul dl    ; multiplicar por ancho de pantalla en bytes
  mov dx, bx  ; Copiar coordenada X
  shr dx, 1   ; Descartar ultimo bit
  add ax, dx  ; Desplazamiento del byte que vamos a manipular
  mov di, ax
  ; and bx, 00000001b	; Usar solo ultimo bit para posicion sub-byte


  .dibujarenglones:

  mov cx, ALTOSPRITE  ; 4 .- Primero dibujamos TODOS los renglones (en renglones par de patalla)

  .looprenglon:

  mov dx, cx ; guardar contador de renglones
  
  mov cx, 4    ; guardar bits a desplazar en el contador

  xor ax, ax	; borrar ax

  lodsb         ; cargar byte en al
  shr ax, cl    ; desplazar esa cantidad de bits
  stosb		; Escribir byte (?)

  dec si
  lodsw
  xchg ah, al
  mov cx, 4
  shr ax, cl    ; desplazar esa cantidad de bits
  stosb		; Escribir byte (?)

  dec si
  lodsw
  xchg ah, al
  mov cx, 4
  shr ax, cl    ; desplazar esa cantidad de bits
  stosb		; Escribir byte (?)

  dec si
  lodsw
  xchg ah, al
  mov cx, 4
  shr ax, cl    ; desplazar esa cantidad de bits
  stosb		; Escribir byte (?)

  dec si
  lodsw
  xchg ah, al
  mov cx, 4
  shr ax, cl    ; desplazar esa cantidad de bits
  stosb		; Escribir byte (?)

  dec si
  lodsw
  xchg ah, al
  mov cx, 4
  shr ax, cl    ; desplazar esa cantidad de bits
  stosb		; Escribir byte (?)

  dec si
  lodsw
  xchg ah, al
  mov cx, 4
  shr ax, cl    ; desplazar esa cantidad de bits
  stosb		; Escribir byte (?)

  dec si
  lodsw
  xchg ah, al
  mov cx, 4
  shr ax, cl    ; desplazar esa cantidad de bits
  stosb		; Escribir byte (?)

  xor ax, ax
  mov ah, [ds:si - 1]
  mov cx, 4
  shr ax, cl
  stosb

  ; movsw	-- Descartar estos
  ; movsw

  add di, ( BYTESPERSCAN - ( ( BWSPRITE + 1 ) ) ) ; Agregar suficientes bytes para que sea siguiente renglon


  mov cx, dx  ; contador de renglones
  loop .looprenglon


  ; 5 .- Después dibujamos los mismos renglones de sprite, ahora en renglones impar de pantalla

  mov cx, es
  cmp cx, MEMCGAODD
  je	.salir

  mov cx, MEMCGAODD ; Dibujar en renglones impar de pantalla CGA 4 Col
  mov es, cx

  sub di, BYTESPERSCAN * ALTOSPRITE  ; Retroceder hasta posicion inicial en pantalla ? (pero ahora en renglon impar)
  sub si, BWSPRITE * ALTOSPRITE  ; retrocedemos hasta posicion inicial de sprite ?

  jmp .dibujarenglones

	; retorno de la función
  .salir:
  ret



borrasprite16:

  ; Parametros:
  ; AX = Coordenada Y
  ; BX = Coordenada X


  ; 0.- Respaldar cosas que deberíamos consevar

  ; 1.- Seleccionar banco de memoria

  mov cx, MEMCGAEVEN
  mov es, cx
  ; mov cx, ax  ; Copiar / respaldar coordenada Y
  ; shr ax, 1 ; Descartar el bit de selección de banco

  ; Multiplicar
  mov dl, BYTESPERSCAN
  mul dl    ; multiplicar por ancho de pantalla en bytes
  shr bx, 1
  add ax, bx  ; Desplazamiento del byte que vamos a manipular
  mov di, ax

  .borrarenglones:

  mov cx, ALTOSPRITE  ; Primero borramos TODOS los renglones del sprite (en renglones par de patalla)
  xor ax, ax  ; Registro AX en ceros

  .looprenglon:

  stosw
  stosw
  stosw
  stosw
  stosb

  add di, BYTESPERSCAN - (  BWSPRITE + 1  ) ; Agregar suficientes bytes para que sea siguiente renglon
  loop .looprenglon

  ; Después dibujamos otra mitad de renglones de sprite, ahora en renglones impar de pantalla

  mov cx, es
  cmp cx, MEMCGAODD
  je	.salir

  mov cx, MEMCGAODD ; Dibujar en renglones impar de pantalla CGA 4 Col
  mov es, cx

  sub di, BYTESPERSCAN * ALTOSPRITE  ; Retroceder hasta posicion inicial en pantalla ? (pero ahora en renglon impar)

  jmp .borrarenglones

	; retorno de la función
  .salir:
  ret


section .data
  ; program data

  kb_int_old_off: dw  0
  kb_int_old_seg: dw  0

  ; Estado de las teclas:
  tecla_esc: db 0
  tecla_up: db 0
  tecla_down: db 0
  tecla_left: db 0
  tecla_right: db 0

  ; Variables del programa:
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
incbin	"monocomposite",0,128

section .bss
  ; uninitialized data

