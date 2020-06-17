
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
  cmp bx, MAPSCREENWIDTH
  jl .loopcols
  inc ax
  add si, MAPWIDTH - MAPSCREENWIDTH
  cmp ax, MAPHEIGHT
  jl .looprows
  ret



dibujasprite16:
  ; Parametros:
  ; BP: sprite

  mov bx, [ds:bp + SPRITE.x]

  ; -1.- Revisar si pixeles están alineados con bytes
  test bx, 0000001b
  jnz dibujasprite16noalineado
  shr bx, 1

  ; 0.- Cargar direccion de mapa de bits

  mov ah, [ds:bp + SPRITE.bw]

  mov al, [ds:bp + SPRITE.ssframe]
  mul ah
  mov ah, [ds:bp + SPRITE.h]
  mul ah

  add ax, [ds:bp + SPRITE.gr0]
  mov si, ax

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
  add si, [ds:bp + SPRITE.bw]
  add di, BYTESPERSCAN
  .espar: pushf

  mov cx, [ds:bp + SPRITE.h]  ; 4 .- Primero dibujamos mitad de renglones (en renglones par de patalla)
  shr cx, 1

  .looprenglon:

  mov dx, cx	; respaldar conteo de renglones
  mov cx, [ds:bp + SPRITE.bw]	; Bytes a copiar por renglon
  rep movsb
  mov cx, dx	; restaurar conteo de renglones

  add di, BYTESPERSCAN; Agregar suficientes bytes para que sea siguiente renglon
  sub di, [ds:bp + SPRITE.bw] ; TODO: ¿Optimizar para acceder solo una vez a ancho de sprite?
  add si, [ds:bp + SPRITE.bw] ; Saltar renglones de ssprite.mapa de bits
  loop .looprenglon

  ; 5 .- Después dibujamos otra mitad de renglones de sprite, ahora en renglones impar de pantalla

  mov cx, MEMCGAODD ; Dibujar en renglones impar de pantalla CGA 4 Col
  mov es, cx

  mov al, [ds:bp + SPRITE.h]
  mov dl, al
  shr al,1
  mov ah, BYTESPERSCAN
  mul ah
  sub di, ax	; Retroceder hasta posicion inicial en pantalla ? (pero ahora en renglon impar)
  mov al, dl
  dec al
  mov ah, [ds:bp + SPRITE.bw]
  mul ah
  sub si, ax	; retrocedemos hasta posicion inicial de sprite + un renglon

  popf ; ¿Necesario?
  jz .espar2
  sub si, [ds:bp + SPRITE.bw]
  sub si, [ds:bp + SPRITE.bw]
  sub di, BYTESPERSCAN
  .espar2:

  mov cx, [ds:bp + SPRITE.h]
  shr cx, 1

  .looprenglon2:

  mov dx, cx	; respaldar conteo de renglones
  mov cx, [ds:bp + SPRITE.bw]	; Bytes a copiar por renglon
  rep movsb
  mov cx, dx	; restaurar conteo de renglones

  add di, BYTESPERSCAN ; Agregar suficientes bytes para que sea siguiente renglon
  sub di, [ds:bp + SPRITE.bw]
  add si, [ds:bp + SPRITE.bw] ; Saltar renglones de ssprite.mapa de bits
  loop .looprenglon2

  ret


dibujasprite16noalineado:

  ; 0.- Cargar direccion de mapa de bits

  mov ah, [ds:bp + SPRITE.bw]

  mov al, [ds:bp + SPRITE.ssframe]
  mul ah
  mov ah, [ds:bp + SPRITE.h]
  mul ah

  add ax, [ds:bp + SPRITE.gr1]
  mov si, ax


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
  add si, [ds:bp + SPRITE.bw]
  add di, BYTESPERSCAN
  .espar pushf

  mov cx, [ds:bp + SPRITE.h]  ; 4 .- Primero dibujamos mitad de renglones (en renglones par de patalla)
  shr cx, 1


  .looprenglon:

  mov dx, cx ; guardar contador de renglones

  ; primer pixel del renglón
  ; Conservar el pixel de la izquierda, que pertenece al fondo?

  mov ah, [es:di]
  and ah, 11110000b
  lodsb
  and al, 00001111b
  or al, ah
  stosb

  mov cx, [ds:bp + SPRITE.bw]	; numero de bytes a copiar
  dec cx

  ; ultimo pixel del renglón
  ; Conservar el pixel de la derecha, que pertenece al fondo?

  rep movsb
  mov ah, [es:di]
  and ah, 00001111b
  lodsb
  and al, 11110000b
  or al, ah
  stosb


  add di, BYTESPERSCAN ; Agregar suficientes bytes para que sea siguiente renglon
  sub di, [ds:bp + SPRITE.bw]
  dec di
  add si, [ds:bp + SPRITE.bw]	; Saltar renglones de sprite.mapa de bits
  dec si

  mov cx, dx  ; contador de renglones
  loop .looprenglon

  ;popf	; Salir por mientras
  ;ret
  ; 5 .- Después dibujamos otra mitad de renglones de sprite, ahora en renglones impar de pantalla

  mov cx, MEMCGAODD ; Dibujar en renglones impar de pantalla CGA 4 Col
  mov es, cx

  mov al, [ds:bp + SPRITE.h]
  mov dl, al
  shr al,1
  mov ah, BYTESPERSCAN
  mul ah
  sub di, ax	; Retroceder hasta posicion inicial en pantalla ? (pero ahora en renglon impar)
  mov al, dl
  dec al
  mov ah, [ds:bp + SPRITE.bw]
  mul ah
  sub si, ax	; retrocedemos hasta posicion inicial de sprite + un renglon


  popf ; ¿Necesario?
  jz .espar2
  sub si, [ds:bp + SPRITE.bw]
  sub si, [ds:bp + SPRITE.bw]
  sub di, BYTESPERSCAN
  .espar2:

  mov cx, [ds:bp + SPRITE.h]
  shr cx, 1

  .looprenglon2:

  mov dx, cx ; guardar contador de renglones

  ; primer pixel del renglón
  ; Conservar el pixel de la izquierda, que pertenece al fondo?

  mov ah, [es:di]
  and ah, 11110000b
  lodsb
  and al, 00001111b
  or al, ah
  stosb

  mov cx, [ds:bp + SPRITE.bw]	; numero de bytes a copiar
  dec cx
  rep movsb

  ; ultimp pixel del renglón
  ; Conservar el pixel de la derecha, que pertenece al fondo?

  rep movsb ; ???
  mov ah, [es:di]
  and ah, 00001111b
  lodsb
  and al, 11110000b
  or al, ah
  stosb


  add di, BYTESPERSCAN	; Agregar suficientes bytes para que sea siguiente renglon
  sub di, [ds:bp + SPRITE.bw]
  dec di
  add si, [ds:bp + SPRITE.bw] ; Saltar renglones de ssprite.mapa de bits
  dec si
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
  add ax, [ds:bp + SPRITE.h]	; ax => c.y = s.ny + s.h

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
  mov al, [colorbackground]
  mov ah, bl	; respaldar ¿altura de Sprite?

  mov bx, [ds:bp + SPRITE.x]
  and bx, 00000001b
  add bx, [ds:bp + SPRITE.bw]

  test cx, cx
  jz .finlooprow
  .looprenglon:
  mov dx, cx
  mov cx, bx
  rep stosb
  mov cx, dx
  add di, BYTESPERSCAN
  sub di, bx
  loop .looprenglon
  .finlooprow:
  xor bh, bh
  mov bl, ah

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
  test dx, dx
  jnz .initlooprow


  .checkhorizontal:
  mov dx, [ds:bp + SPRITE.x]
  mov bx, [ds:bp + SPRITE.nx]
  cmp dx, bx
  je .salir
  ja .mizq
  .mder:	; dx => c.x = s.x
  sub bx, dx	; bx => c.w = s.nx - s.x
  jmp .sig3
  .mizq:

  xchg dx, bx	; bx => s.x, dx = s.nx
  sub bx, dx	; bx => c.w = s.x - s.nx
  add dx, [ds:bp + SPRITE.pxw]	; dh => c.x = s.nx + s.w

  .sig3:
  ; dx => c.x
  ; bx => c.w

  ; Calcular movimiento vertical para borrado de seccion horizontal
  mov bh, [ds:bp + SPRITE.h]
  mov al, [ds:bp + SPRITE.y]
  mov ah, [ds:bp + SPRITE.ny]
  cmp al, ah
  jl .mdown
  xchg al, ah	; al => s.ny, ah => s.y
  .mdown:
  mov cl, ah
  sub ah, al
  sub bh, ah	; bh => c.h, al => c.y
  je .salir	; ?? Salir en caso de que sea menor o igual a cero ?
  mov al, cl
  .clearhorizontal:
  ; dx => c.x
  ; bl => c.w
  ; bh => c.h
  ; al => c.y

  mov cx, MEMCGAEVEN
  mov es, cx
  mov si, ax	; si => c.y
  shr al, 1	; descartar bit de seleccion de banco
  mov ah, BYTESPERSCAN	; multiplicar por ancho de pantalla en bytes
  mul ah	; ax => desplazamiento en bytes del renglon
  ; xor cx, cx
  mov cx, dx	; cx => c.x
  shr cx, 1	; descartar utlimo bit	(posicion de pixel intra-byte)
  add ax, cx	; ax => Direccion de memoria donde empezamos a borrar
  mov di, ax	; Destination index = posicion inicial a borrar
		; ax queda libre para usar en otras cosas

  xor ch, ch
  mov cl, bh	; cx => c.h
  shr cx, 1	; dividir numero de renglones entre dos (para escaneo par)
  test si, 00000001b	; ver si coordenada y es par
  jz .espar3
  add di, BYTESPERSCAN	; Comenzar en un renglón más abajo en caso de coordenada impar
  jmp .sig4
  .espar3:
  ; incrementar numero de renglones en escaneo par en caso de que renglones
  ; totales sea impar y coordenada y par

  test bh, 00000001b
  jz .sig4
  inc cx
  .sig4:
  .initlooprowh:
  ; push bx	; ¿Aun es necesario respaldar estas variables?
  push dx
  push bx
  mov al, [colorbackground]
  ; mov al, 00
  mov ah, bl	; ah => c.w
  shr ah, 1	; dividir entre dos pixeles por byte
  mov dh, bl
  or dh, dl
  and dh, 00000001b	; agregar un byte si numero de pixeles es impar
  add ah, dh	; ah => numero de bytes a escribir horizontalmente
  test cx, cx
  jz .finlooprowh
  .looprowh:
  mov bx, cx	; respaldar conteo de renglones
  xor ch, ch
  mov cl, ah
  rep stosb
  mov cx, bx	; restaurar conteo de renglones
  xor bx, bx
  mov bl, ah
  sub bx, BYTESPERSCAN
  sub di, bx
  mov bx, cx
  loop .looprowh
  .finlooprowh:
  pop bx
  pop dx

  mov cx, es
  cmp cx, MEMCGAODD
  je .salir

  mov cx, MEMCGAODD
  mov es,cx

  ; xor ax, ax
  mov ax, si	; al => c.y
  shr al, 1
  mov ah, BYTESPERSCAN
  mul ah	; ax => desplazamiento en bytes del renglon
  ; xor cx, cx
  mov cx, dx	; cx => c.x
  shr cx, 1	; descartar utlimo bit (posicion de pixel intra-byte)
  add ax, cx
  mov di, ax

  xor cx, cx
  mov cl, bh	; cx => c.h
  shr cx, 1	; dividir numero de renglones entre dos (para escaneo impar)
  test si, 00000001b	; ver si coordenada c.y es impar
  jz .espar4
  test bh, 00000001b	; y además altura c.h es impar
  jz .espar4
  inc cx		; si ambos sin impares: incrementar numero de renglones
  			; a dibujar en lineas de escaneo impar de pantalla
  .espar4:
  jmp .initlooprowh
  test cx, cx
  ;jz .salir		; salir en caso de que conteo de renglones sea cero
  jnz .initlooprowh



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

  mov dx, [ds:bp + SPRITE.bw]	; guardar ancho de sprite en pixeles

  mov bx, [ds:bp + SPRITE.x]
  shr bx, 1

  jnc .sig1	; Incrementar numero de bytes a borrar si la alineacion x es non
  inc dx
  .sig1:

  add ax, bx  ; Desplazamiento del byte que vamos a manipular
  mov di, ax

  ; En caso de que coordenada Y sea impar, comenzar a borrar sprite desde
  ; la segunda fila de pixeles del mapa de bits en coordenada par de pantalla.
  test cx, 00000001b
  jz .espar
  add di, BYTESPERSCAN
  .espar pushf

  ; Primero borramos mitad de renglones (en renglones par de patalla)
  mov cx, [ds:bp + SPRITE.h]
  shr cx, 1

  ; xor ax, ax  ; Registro AX en ceros
  ; mov ax, 1010101010101010b <= debug
  mov ax, [colorbackground]

  .looprenglon:
  mov bx, cx
  mov cx, dx
  rep stosb
  mov cx, bx

  add di, BYTESPERSCAN		; Agregar suficientes bytes para que sea siguiente renglon
  sub di, dx
  loop .looprenglon

  ; Después dibujamos otra mitad de renglones de sprite, ahora en renglones impar de pantalla

  mov cx, MEMCGAODD ; Dibujar en renglones impar de pantalla CGA 4 Col
  mov es, cx

  mov bx, ax
  mov al, [ds:bp + SPRITE.h]
  shr al,1
  mov ah, BYTESPERSCAN
  mul ah
  sub di, ax	; Retroceder hasta posicion inicial en pantalla ? (pero ahora en renglon impar)
  mov ax, bx

  popf ; ¿Necesario?
  jz .espar2
  sub di, BYTESPERSCAN
  .espar2:

  mov cx, [ds:bp + SPRITE.h]
  shr cx, 1

  .looprenglon2:
  mov bx, cx
  mov cx, dx
  rep stosb
  mov cx, bx

  add di, BYTESPERSCAN		; Agregar suficientes bytes para que sea siguiente renglon
  sub di, dx
  loop .looprenglon2

  ret


drawtilesimple:
  ; AX = Y Coordinate of tile
  ; BX = X Coordinate of tile
  ; CX = Tile Code
  push si
  push ax	; Respaldar AX y BX
  push bx

  ; 1 .- Seleccionar banco de memoria
  mov dx, MEMCGAEVEN
  mov es, dx
  mov dx, cs
  mov ds, dx

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


  lea si, [tilesgraphics]
  ; mov si, bx
  mov al, dl
  mov ah, 64
  mul ah
  add si, ax
  ; mov si, bx

  .draw:
  mov cx, ( ALTOTILE / 2 )  ; Primero dibujamos mitad de renglones (en renglones par de patalla)

  .looprenglon:
  mov dx, cx	; respaldar cx
  mov cx, ( ANCHOTILE / PXB )
  rep movsb
  mov cx, dx	; Reestablecer cx
  add di, BYTESPERSCAN - ( ANCHOTILE / PXB )
  add si, ( ANCHOTILE / PXB )
  loop .looprenglon

  mov cx, es
  cmp cx, MEMCGAODD
  je .salir

  mov cx, MEMCGAODD
  mov es, cx
  sub di, BYTESPERSCAN * ( ALTOTILE / 2 )
  sub si, ( ANCHOTILE / PXB ) * ( ALTOTILE - 1 )
  jmp .draw

  .salir:
  pop bx	; Restaurar bx y ax
  pop ax
  pop si
  ret


conviertecomposite2tandy:
  ; bx => graficos a convertir
  ; cx => cantidad de bytes a convertir
  push si
  push di

  mov ax, cs	; Esto sólo funciona en ejecutables ".com" Cambiar en caso de ".exe"
  mov ds, ax
  mov es, ax

  mov si, bx
  mov di, bx

  mov bx, comp2tdy_table

  .loopbyte:
  lodsb
  mov dx, cx
  mov ah, al
  and al, 00001111b
  xlatb
  xchg ah, al
  mov cl, 4
  shr al, cl
  xlatb
  mov cl, 4
  shl al, cl
  or al, ah
  stosb
  mov cx, dx
  loop .loopbyte

  pop di
  pop si
  ret


inicializaspritegrafico:
  ; Parametros:
  ; BP => spritegrafico

  mov bx, ds
  mov es, bx

  mov si, [ds:bp + SPRITESHEET.gr0]

  mov ah, [ds:bp + SPRITESHEET.w]

  %rep ilog2e( PXB )
  shr ah, 1
  %endrep

  mov al, [ds:bp + SPRITESHEET.framescount]
  mul ah
  mov ah, [ds:bp + SPRITESHEET.h]	; Precaución: Estamos asumiendo que
  mul ah		; resultado de multiplicacion cabe en un solo byte (AL)
  inc ax
  mov dx, ax
  mov cx, ax
  call malloc		; Asignar memoria
  mov di, bx		; Memoria asignada en Destination Index
  mov [ds:bp + SPRITESHEET.gr1], bx		; Memoria asignada en estructura Sprite

  .px0:		; guardar el primer pixel con desplazamiento de bits

  mov cx, 4 	; guardar bits a desplazar en el contador
  xor ax, ax	; borrar ax
  lodsb		; cargar byte en al
  shr ax, cl	; desplazar esa cantidad de bits
  stosb		; Escribir byte

  mov cx, dx
  dec cx
  dec cx

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

  ret

conectaspritegraficos:
  ; Parametros:
  ; BP => sprite

  mov bx, [ds:bp + SPRITE.spritesheet]

  mov ax, [bx + SPRITESHEET.gr0]
  mov [ds:bp + SPRITE.gr0], ax

  mov ax, [bx + SPRITESHEET.gr1]
  mov [ds:bp + SPRITE.gr1], ax

  mov ax, [bx + SPRITESHEET.h]
  mov [ds:bp + SPRITE.h], ax

  mov ax, [bx + SPRITESHEET.w]
  mov [ds:bp + SPRITE.pxw], ax

  %rep ilog2e( PXB )
  shr ax, 1
  %endrep

  mov [ds:bp + SPRITE.bw], ax

  ret


doscroll:
  ; CX: Direccion de scroll
  ; 1 => izquierda
  ; 0 => derecha

  mov si, map1

  mov ax, [hscroll]
  test cx, cx
  jnz .mleft
  .mright:
  mov bx, ( BYTESPERSCAN / BYTESPERHSCROLL )
  add bx, ax
  inc ax
  jmp .sig0
  .mleft:
  dec ax
  mov bx, ax
  .sig0:
  mov [hscroll], ax

  mov ax, bx
  %rep ilog2e( BYTESPERHSCROLL )
  shl ax, 1
  %endrep
  mov di, ax	; Desplazamiento en memoria de video

  mov ax, bx
  %rep ilog2e( HSCROLLSPERTILE )
  shr ax, 1
  %endrep
  add si, ax

  mov ax, bx
  and ax, 1	; TODO: cambiar para que funcione para distintos valoes de HSCROLLSPERTILE
  mov ah, BYTESPERHSCROLL
  mul ah
  add ax, tilesgraphics
  mov dx, ax


  ; VSync

  mov cx, MAPHEIGHT
  .tilerowloop:
  lodsb
  mov ah, 64	; TODO: Sustituir con caulculo de tamaño de tile en bytes en preprocesador
  mul ah
  push si
  push cx

  ; lea si, [tilesgraphics]
  mov si, dx
  add si, ax
  ; drawtile sub
  mov cx, MEMCGAEVEN
  mov es, cx
  ; mov cx, cs
  ; mov ds, cx

  .draw:
  mov cx, ( ALTOTILE / 2 ) ; Primero dibujamos mitad de renglones (renglones par de pantalla)

  .scanlineloop:
  ; mov dx, cx	; respaldar CX
  ; mov cx,
  %rep ( BYTESPERHSCROLL / 2 )	; NOTA: Por ahora solo acepta multiplos de 2, por velocidad
  movsw
  %endrep
  add di, BYTESPERSCAN - BYTESPERHSCROLL
  add si, ( ANCHOTILE / PXB ) + ( ( ANCHOTILE / PXB ) - BYTESPERHSCROLL )
  loop .scanlineloop


  mov cx, es
  cmp cx, MEMCGAODD
  je .sigtile

  mov cx, MEMCGAODD
  mov es, cx
  sub di, BYTESPERSCAN * ( ALTOTILE / 2 )
  sub si, ( ( ANCHOTILE / PXB ) * ( ALTOTILE - 1 ) )
  jmp .draw

  .sigtile:
  pop cx
  pop si
  add si, MAPWIDTH - 1
  loop .tilerowloop


  ; Hacer el scroll por harware
  mov dx, 03d4h
  mov al, 0dh
  out dx, al
  mov al, [hscroll]
  mov dx, 03d5h
  out dx, al
ret

section .data
  ; program data

  hscroll: dw 0

  ; Trabla de equivalencia entre paletas de colores Composite => Tandy
  comp2tdy_table:

  db 0, 2, 1, 3, 4, 7, 5, 11, 6, 10, 8, 10, 12, 14, 13, 15


