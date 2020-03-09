
CPU 8086

  %use ifunc

  %define VIDEOBIOS 0x10
  %define SETVIDEOMODE 0
  %define CGA6 0x06
  %define WIDTHPX 160d
  %define HEIGHTPX 200d
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
  %define REBOTEY 14
  %define ANCHOSPRITE 16
  %define ALTOSPRITE 32
  %define ANCHOTILE 16
  %define ALTOTILE 32
  %define MAPWIDTH 10
  %define MAPHEIGHT 6

  %define BWSPRITE ( ANCHOSPRITE / PXB )  ; Ancho de Sprite en Bytes
  %define SPRITESUB	4		; Number of reserved memory words for Sprite subclasess

  ; data structures

  struc SPRITE

    .graphics:	resw 1	; Pointer to graphic data
    .frame:	resw 1	; Pointer to function defining per frame logic
    .x		resw 1
    .y		resw 1
    .nx		resw 1
    .ny		resw 1
    .next	resw 1	; Pointer to nexts prite in linked list
    ; .sub	resw SPRITESUB	; Subclass properties

  endstruc

  struc SPRITEPHYS	; Sprite with Physics

    .sprite:	resb SPRITE_size
    .vuelox:	resw 1
    .deltay:	resw 1
    .parado:	resw 1

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


  ; x .- Draw map
  mov dx, map1
  call drawmap

  ; 4 .- Dibujar sprite en su posicion inicial
  mov bp, playersprite
  call dibujasprite16

  ;jmp fin	; Temporal

  frame:

  call playerframe
  VSync
  call borraspritemov

  mov ax, [ds:bp + SPRITE.ny]
  mov bx, [ds:bp + SPRITE.nx]
  mov [ds:bp + SPRITE.y], ax
  mov [ds:bp + SPRITE.x], bx


  call dibujasprite16

  ; repetir ciclo
  jmp frame


drawmap:
  ; DX = Map data
  xor ax, ax	; AX = 0
  mov si, dx	; Load Map data on Source index

  .looprows:
  
  xor bx, bx	; BX = 0
  .loopcols:
  mov cx, ax
  lodsb
  xchg ax, cx
  call drawtilesimple
  inc bx
  cmp bx, MAPWIDTH
  jl .loopcols
  inc ax
  cmp ax, MAPHEIGHT
  jl .looprows
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


playerframe:
  ; Parametros:
  ; BP => sprite

  ; 1.- Leer el teclado

  mov al, [tecla_esc] ; ¿está presionada esta tecla?
  test al, al
  jnz fin

  .test_left:
  mov al, [tecla_left] ; ¿está presionada esta tecla?
  test al, al
  jz .sig1

  .movizq:
  dec word [ds:bp + SPRITEPHYS.vuelox]
  jmp .testright

  .sig1:
  mov ax, [ds:bp + SPRITEPHYS.vuelox]
  cmp ax, 0
  jnl .testright
  inc word [ds:bp + SPRITEPHYS.vuelox]

  .testright:
  mov al, [tecla_right] ; ¿está presionada esta tecla?
  test al, al
  jz .sig2

  .movder:
  inc word [ds:bp + SPRITEPHYS.vuelox]
  jmp .calcx

  .sig2:
  mov ax, [ds:bp + SPRITEPHYS.vuelox]
  cmp ax, 0
  jng .calcx
  dec word [ds:bp + SPRITEPHYS.vuelox]



  .calcx:    ; 2.- calcular x

  mov ax, [ds:bp + SPRITE.x]
  mov bx, [ds:bp + SPRITEPHYS.vuelox]
  mov dx, bx
  mov cl, 2
  sar dx, cl
  add ax, dx

  ; 1.1.- revisar que no se salga

  cmp ax, WIDTHPX - ANCHOSPRITE
  jng .sig3
  mov ax, WIDTHPX - ANCHOSPRITE
  neg bx	; Rebotar, reduciendo velocidad a la mitad
  sar bx, 1
  .sig3:
  cmp ax, 0
  jnl .sig4
  mov ax, 0
  neg bx	; Rebotar, reduciendo velocidad a la mitad
  sar bx, 1
  .sig4:
  mov [ds:bp + SPRITE.nx], ax
  mov [ds:bp + SPRITEPHYS.vuelox], bx

  .saltar:
  mov al, [tecla_up] ; ¿está presionada esta tecla?
  test al, al
  jz .calcdy

  mov ax, [ds:bp + SPRITEPHYS.parado] ; Tiene que estar parado para poder saltar
  test ax, ax
  jz .calcdy

  ; Ahora sí: Saltar porque estamos parados y con la tecla saltar presionada
  mov bx, 0 - REBOTEY
  mov [ds:bp + SPRITEPHYS.deltay], bx
  mov bx, 0
  mov [ds:bp + SPRITEPHYS.parado], bx


  .calcdy:  ; 2.- Calcular delta Y
  mov dx, [ds:bp + SPRITEPHYS.deltay]
  add dx, GRAVEDAD
  mov [ds:bp + SPRITEPHYS.deltay], dx

  .calcy:      ; 3.- calcular y
  
  mov ax, [ds:bp + SPRITE.y]
  mov bx, [ds:bp + SPRITEPHYS.deltay]
  add ax, bx

  ; 1.1.- revisar que no se salga

  cmp ax, HEIGHTPX - ALTOSPRITE
  jng .sig5
  mov ax, HEIGHTPX - ALTOSPRITE
  mov bx, 0
  mov word [ds:bp + SPRITEPHYS.parado], 1
  .sig5:
  cmp ax, 0
  jnl .sig6
  mov ax, 0
  mov bx, 0
  .sig6:
  mov [ds:bp + SPRITE.ny], ax
  mov [ds:bp + SPRITEPHYS.deltay], bx

  ; Fin de logica del jugador por frame
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
  ; BP: sprite

  mov bx, [ds:bp + SPRITE.x]

  ; -1.- Revisar si pixeles están alineados con bytes
  test bx, 0000001b
  jnz dibujasprite16noalineado
  shr bx, 1

  ; 0.- Respaldar cosas que deberíamos consevar

  mov dx, [ds:bp + SPRITE.graphics]
  mov si, dx  ; Cargar direccion de mapa de bits

  ; 1.- Seleccionar banco de memoria

  mov cx, MEMCGAEVEN
  mov es, cx
  ; mov cx, ax  ; Copiar / respaldar coordenada Y
  mov ax, [ds:bp + SPRITE.y]
  mov cx, ax
  shr ax, 1 ; Descartar el bit de selección de banco

  ; 2.- Multiplicar
  mov dl, BYTESPERSCAN
  mul dl    ; multiplicar por ancho de pantalla en bytes
  add ax, bx  ; Desplazamiento del byte que vamos a manipular
  mov di, ax

  ; 3.- En caso de que coordenada Y sea impar, comenzar a dibujar sprite desde
  ; la segunda fila de pixeles del mapa de bits en coordenada par de pantalla.
  ; mov cx, [ds:bp + SPRITE.y]
  test cx, 00000001b
  jz .espar
  add si, BWSPRITE
  add di, BYTESPERSCAN
  .espar: pushf

  mov cx, ( ALTOSPRITE / 2 )  ; 4 .- Primero dibujamos mitad de renglones (en renglones par de patalla)

  .looprenglon:

  mov dx, cx	; respaldar conteo de renglones
  mov cx, ( ANCHOSPRITE / ( PXB * 2 ) )	; Palabras a copiar por renglon
  rep movsw
  mov cx, dx	; restaurar conteo de renglones

  add di, BYTESPERSCAN -  BWSPRITE; Agregar suficientes bytes para que sea siguiente renglon
  add si, BWSPRITE ; Saltar renglones de ssprite.mapa de bits
  loop .looprenglon

  ; 5 .- Después dibujamos otra mitad de renglones de sprite, ahora en renglones impar de pantalla

  mov cx, MEMCGAODD ; Dibujar en renglones impar de pantalla CGA 4 Col
  mov es, cx

  sub di, BYTESPERSCAN * ( ALTOSPRITE / 2 )  ; Retroceder hasta posicion inicial en pantalla ? (pero ahora en renglon impar)
  sub si, BWSPRITE * ( ALTOSPRITE - 1 )   ; retrocedemos hasta posicion inicial de sprite + un renglon

  popf ; ¿Necesario?
  jz .espar2
  sub si, BWSPRITE * 2
  sub di, BYTESPERSCAN
  .espar2:

  mov cx, ( ALTOSPRITE / 2 )

  .looprenglon2:

  mov dx, cx	; respaldar conteo de renglones
  mov cx, ( ANCHOSPRITE / ( PXB * 2 ) )	; Palabras a copiar por renglon
  rep movsw
  mov cx, dx	; restaurar conteo de renglones

  add di, BYTESPERSCAN -  BWSPRITE ; Agregar suficientes bytes para que sea siguiente renglon
  add si, BWSPRITE ; Saltar renglones de ssprite.mapa de bits
  loop .looprenglon2

  ret

dibujasprite16noalineado:

  ; 0.- Respaldar cosas que deberíamos consevar

  mov dx, [ds:bp + SPRITE.graphics]
  mov si, dx  ; Cargar direccion de mapa de bits

  ; 1.- Seleccionar banco de memoria

  mov cx, MEMCGAEVEN
  mov es, cx

  mov ax, [ds:bp + SPRITE.y]
  mov cx, ax  ; Copiar / respaldar coordenada Y
  shr ax, 1 ; Descartar el bit de selección de banco

  ; 2.- Multiplicar
  mov dl, BYTESPERSCAN
  mul dl    ; multiplicar por ancho de pantalla en bytes
  mov bx, [ds:bp + SPRITE.x]
  mov dx, bx  ; Copiar coordenada X
  shr dx, 1   ; Descartar ultimo bit
  add ax, dx  ; Desplazamiento del byte que vamos a manipular
  mov di, ax
  and bx, 00000001b	; Usar solo ultimo bit para posicion sub-byte

  ; 3.- En caso de que coordenada Y sea impar, comenzar a dibujar sprite desde
  ; la segunda fila de pixeles del mapa de bits en coordenada par de pantalla.
  test cx, 00000001b
  jz .espar
  add si, BWSPRITE
  add di, BYTESPERSCAN
  .espar pushf

  mov cx, ( ALTOSPRITE / 2 )  ; 4 .- Primero dibujamos mitad de renglones (en renglones par de patalla)


  .looprenglon:

  mov dx, cx ; guardar contador de renglones
  
  mov cx, 4    ; guardar bits a desplazar en el contador

  xor ax, ax	; borrar ax

  lodsb         ; cargar byte en al
  shr ax, cl    ; desplazar esa cantidad de bits
  stosb		; Escribir byte (?)

  mov cx, ( ( ANCHOSPRITE / PXB ) - 1 )	; numero de bytes a copiar
  .loopbyte:
  mov bx, cx
  dec si
  lodsw
  xchg ah, al
  mov cx, 4
  shr ax, cl    ; desplazar esa cantidad de bits
  stosb		; Escribir byte (?)
  mov cx, bx
  loop .loopbyte

  xor ax, ax
  mov ah, [ds:si - 1]
  mov cx, 4
  shr ax, cl
  stosb

  ; movsw	-- Descartar estos
  ; movsw

  add di, ( BYTESPERSCAN - ( BWSPRITE + 1 ) ) ; Agregar suficientes bytes para que sea siguiente renglon
  add si, BWSPRITE ; Saltar renglones de sprite.mapa de bits

  mov cx, dx  ; contador de renglones
  loop .looprenglon

  ;popf	; Salir por mientras
  ;ret
  ; 5 .- Después dibujamos otra mitad de renglones de sprite, ahora en renglones impar de pantalla

  mov cx, MEMCGAODD ; Dibujar en renglones impar de pantalla CGA 4 Col
  mov es, cx

  sub di, ( BYTESPERSCAN * ( ALTOSPRITE / 2 ) )  ; Retroceder hasta posicion inicial en pantalla ? (pero ahora en renglon impar)
  sub si, BWSPRITE * ( ALTOSPRITE - 1 )  ; retrocedemos hasta posicion inicial de sprite ?

  popf ; ¿Necesario?
  jz .espar2
  sub si, BWSPRITE * 2
  sub di, BYTESPERSCAN
  .espar2:

  mov cx, ( ALTOSPRITE / 2 )

  .looprenglon2:

  mov dx, cx ; guardar contador de renglones
  
  mov cx, 4    ; guardar bits a desplazar en el contador

  xor ax, ax	; borrar ax

  lodsb         ; cargar byte en al
  shr ax, cl    ; desplazar esa cantidad de bits
  stosb		; Escribir byte (?)

  mov cx, ( ( ANCHOSPRITE / PXB ) - 1 )	; numero de bytes a copiar
  .loopbyte2:
  mov bx, cx
  dec si
  lodsw
  xchg ah, al
  mov cx, 4
  shr ax, cl    ; desplazar esa cantidad de bits
  stosb		; Escribir byte (?)
  mov cx, bx
  loop .loopbyte2

  xor ax, ax
  mov ah, [ds:si - 1]
  mov cx, 4
  shr ax, cl
  stosb


  add di, ( BYTESPERSCAN - ( BWSPRITE + 1 ) ) ; Agregar suficientes bytes para que sea siguiente renglon
  add si, BWSPRITE ; Saltar renglones de ssprite.mapa de bits
  mov cx, dx  ; contador de renglones
  loop .looprenglon2


  ; Fin. Retornar
  ret

borraspritemov:
  ; Optimized routine for erasing only the pixels that needs to be erased
  ; DS:BP => Sprite

  ; 1.- Check if moved vertically

  .checkvertical:
  mov ax, [ds:bp + SPRITE.y]
  mov bx, [ds:bp + SPRITE.ny]
  cmp ax, bx
  je .checkhorizontal	; Si son iguales es que no hay mov vertical
  jg .bkvertical	; Si y es mayor que ny, vamos hacia abajo
			; Si y es nemor que ny, vamos hacia arriba
			; ax => c.y = s.y
  sub bx, ax		; bx => c.h = s.ny - s.y
  jmp .clearvertical

  .bkvertical:
  xchg ax, bx		; ax => s.ny, bx => s.y
  sub bx, ax		; bx => s.ny - s.y	(numero negativo)
  ; neg bx		; bx => c.h = s.y - s.ny (numero positivo)
  add ax, ALTOSPRITE	; ax => c.y = s.ny + s.h

  .clearvertical:
  ; ax => c.y
  ; bx => c.h

  ; mov ax, 3
  ; mov bx, 4

  mov cx, MEMCGAEVEN
  mov es, cx
  mov cx, ax	; respaldar coordenada y
  shr ax, 1	; Descartar bit de seleccion de banco
  ; multiplicar
  mov dx, BYTESPERSCAN
  mul dl	; multiplicar por ancho de pantalla en bytes
  mov dx, [ds:bp + SPRITE.x]
  shr dx, 1	; Descartar ultimo bit (posicion de pixel dentro del byte)
  add ax, dx	; Direccion en memoria donde comenzamos a borrar
  mov di, ax

  ; En caso de que coordenada Y sea impar, comenzar a borrar desde
  ; la segunda fila de pixeles del mapa de bits en coordenada par de pantalla.
  mov dx, bx
  shr dx, 1
  mov ax, bx
  and ax, 00000001b
  test cx, 00000001b
  pushf
  jz .espar
  add di, BYTESPERSCAN
  jmp .sig1
  .espar:
  add dx, ax
  .sig1:
  .initlooprow:
  mov cx, dx
  mov ax, 00h
  test cx, cx
  jz .finlooprow
  .looprenglon:
  mov dx, cx
  mov cx, BWSPRITE
  rep stosb
  mov cx, dx
  add di, BYTESPERSCAN - ( BWSPRITE )
  loop .looprenglon
  .finlooprow:

  mov cx, es
  cmp cx, MEMCGAODD
  je .checkhorizontal

  mov cx, MEMCGAODD
  mov es, cx
  mov ax, bx
  shr ax, 1
  mov dl, BYTESPERSCAN
  mul dl
  sub di, ax ; TODO: Ver como optimizar esto, junto con el siguiente 'jz .espar2'
  ; sub di, BYTESPERSCAN * ( ALTOSPRITE / 2 )
  mov dx, bx
  shr dx, 1
  mov ax, bx
  and ax, 00000001b
  popf
  jz .espar2
  add dx, ax
  sub di, BYTESPERSCAN
  jmp .sig2
  .espar2:
  test ax, 00000001b
  jz .sig2
  sub di, BYTESPERSCAN
  .sig2:
  mov cx, dx
  mov ax, 00h
  test cx, cx
  jz .checkhorizontal
  jmp .looprenglon


  .checkhorizontal:
  mov dh, [ds:bp + SPRITE.x]
  mov dl, [ds:bp + SPRITE.nx]
  cmp dh, dl
  je .salir
  jg .mizq
  .mder:	; dh => c.x = s.x
  sub dl, dh	; dl => c.w = s.nx - s.x
  jmp .sig3
  .mizq:
  xchg dh, dl	; dl => s.x, dh = s.nx
  sub dl, dh	; dl => c.w = s.x - s.nx
  add dh, ANCHOSPRITE	; dh => c.x = s.nx + s.w
  .sig3:
  ; dh => c.x
  ; dl => c.w

  ; Calcular movimiento vertical para borrado de seccion horizontal
  mov bh, ALTOSPRITE
  mov al, [ds:bp + SPRITE.y]
  mov bl, [ds:bp + SPRITE.ny]
  cmp al, bl
  jl .mdown
  xchg al, bl	; al => s.ny, bl => s.y
  .mdown:
  add bh, bl
  sub bh, al	; bh => c.h, al => c.y
  jle .salir	; ?? Salir en caso de que sea menor o igual a cero ?
  .clearhorizontal:
  ; dh => c.x
  ; dl => c.w
  ; bh => c.h
  ; al => c.y
  
  .salir:
  ret

borrasprite16:

  ; Parametros:
  ; BP => sprite

  ; 1.- Seleccionar banco de memoria

  mov cx, MEMCGAEVEN
  mov es, cx
  mov ax, [ds:bp + SPRITE.y]
  mov cx, ax  ; Copiar / respaldar coordenada Y
  shr ax, 1 ; Descartar el bit de selección de banco

  ; Multiplicar
  mov dl, BYTESPERSCAN
  mul dl    ; multiplicar por ancho de pantalla en bytes
  mov bx, [ds:bp + SPRITE.x]
  shr bx, 1
  add ax, bx  ; Desplazamiento del byte que vamos a manipular
  mov di, ax

  ; En caso de que coordenada Y sea impar, comenzar a borrar sprite desde
  ; la segunda fila de pixeles del mapa de bits en coordenada par de pantalla.
  test cx, 00000001b
  jz .espar
  add di, BYTESPERSCAN
  .espar pushf

  mov cx, ( ALTOSPRITE / 2 )  ; Primero borramos mitad de renglones (en renglones par de patalla)
  xor ax, ax  ; Registro AX en ceros
  ; mov ax, 1010101010101010b <= debug

  .looprenglon:

  stosw
  stosw
  stosw
  stosw
  stosb

  add di, BYTESPERSCAN - ( BWSPRITE + 1 ) ; Agregar suficientes bytes para que sea siguiente renglon
  loop .looprenglon

  ; Después dibujamos otra mitad de renglones de sprite, ahora en renglones impar de pantalla

  mov cx, MEMCGAODD ; Dibujar en renglones impar de pantalla CGA 4 Col
  mov es, cx

  sub di, BYTESPERSCAN * ( ALTOSPRITE / 2 )  ; Retroceder hasta posicion inicial en pantalla ? (pero ahora en renglon impar)

  popf ; ¿Necesario?
  jz .espar2
  sub di, BYTESPERSCAN
  .espar2:

  mov cx, ( ALTOSPRITE / 2 )

  .looprenglon2:

  stosw
  stosw
  stosw
  stosw
  stosb

  add di, BYTESPERSCAN - ( BWSPRITE + 1 ) ; Agregar suficientes bytes para que sea siguiente renglon
  loop .looprenglon2

  ret


drawtilesimple:
  ; AX = Y Coordinate of tile
  ; BX = X Coordinate of tile
  ; CX = Tile Code
  push ax	; Respaldar AX y BX
  push bx

  ; 1 .- Seleccionar banco de memoria
  mov dx, MEMCGAEVEN
  mov es, dx

  ; 2 .- Multiplicar para calcular desplazamiento
  mov dl, BYTESPERSCAN
  mul dl	; Multiply by screen width in bytes
  mov dx, cx
  mov cx, ( ilog2e( ALTOTILE ) - 1 )
  shl ax, cl

  ; 3 .- Multiplicar X por ancho de TILE
  mov cx, ilog2e(ANCHOTILE / PXB)
  shl bx, cl

  ; 4 .- Sumar
  add ax, bx
  mov di, ax	; Destination Index

  mov ax, dx		 ; Sprite Simple: sólo colorear (rellenar todo ax de los mismos 4 bits)
  mov ah, al
  mov cl, (8 / PXB)
  shl ah, cl
  or al, ah
  mov ah, al

  .draw:
  mov cx, ( ALTOTILE / 2 )  ; Primero dibujamos mitad de renglones (en renglones par de patalla)

  .looprenglon:
  mov dx, cx	; respaldar cx
  mov cx, ( ANCHOTILE / ( PXB * 2 ) )
  rep stosw
  mov cx, dx	; Reestablecer cx
  add di, BYTESPERSCAN - ( ANCHOTILE / PXB )
  loop .looprenglon

  mov cx, es
  cmp cx, MEMCGAODD
  je .salir

  mov cx, MEMCGAODD
  mov es, cx
  sub di, BYTESPERSCAN * ( ALTOTILE / 2 ) 
  jmp .draw

  .salir:
  pop bx	; Restaurar bx y ax
  pop ax
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

  paleta:
  db 1

  playersprite:
    istruc SPRITEPHYS
    at SPRITE.graphics, dw spritemonigote
    at SPRITE.frame, dw playerframe
    at SPRITE.x, dw 0d
    at SPRITE.y, dw 40d
    at SPRITE.nx, dw 0
    at SPRITE.ny, dw 0
    at SPRITE.next, dw 0
    at SPRITEPHYS.vuelox, dw 0
    at SPRITEPHYS.deltay,dw 0
    at SPRITEPHYS.parado,dw 0

  firstsprite:
  dw playersprite

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

map1:

  db 0, 12, 10, 11, 8, 9, 0, 0, 0, 0
  db 0, 6, 6, 6, 6, 0, 0, 13, 0, 0
  db 0, 0, 0, 0, 0, 0, 7, 0, 14, 15 
  db 4, 0, 0, 0, 0, 0, 0, 0, 4, 2
  db 1, 5, 0, 0, 0, 0, 0, 2, 0, 0
  db 1, 0, 0, 0, 0, 1, 0, 0, 0, 0


spritemonigote:
incbin	"mdoble.bin",0,256

section .bss
  ; uninitialized data

