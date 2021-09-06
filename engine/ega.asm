; Copyright 2021 Jesús Abelardo Saldívar Aguilar


  ; Aritmetica de constantes gráficas
  %define ANCHOTILEBYTES    (ANCHOTILE / EGAPXPERBYTE)

drawmap.ega:
  ; DX = Map data
  xor ax, ax	; AX = 0
  mov si, dx	; Load Map data on Source index

  .looprows:

  xor bx, bx	; BX = 0
  .loopcols:
  mov cx, ax
  lodsb
  xchg ax, cx
  call drawtile.ega
  inc bx
  cmp bx, MAPSCREENWIDTH
  jl .loopcols
  inc ax
  add si, MAPWIDTH - MAPSCREENWIDTH
  cmp ax, MAPHEIGHT
  jl .looprows
  ret

drawsprite.ega:
  ret

borrasprite.ega:
  ret

drawtile.ega:
  ; AX = Y Coordinate of tile
  ; BX = X Coordinate of tile
  ; CX = Tile Code
  push ds
  push si
  push ax	; Respaldar AX y BX
  push bx

  ; 1 .- Calcular DI (Destination Index)
  ; 1.1 .- Multiplicar para calcular desplazamiento
  mov dl, WIDTHBYTES    ; NOTA ¿usar 8 ó 16 bits?
  mul dl
  mov dx, cx
  mov cx, ilog2e( ALTOTILE )
  shl ax, cl


  ; 1.2 .- Multiplicar X por ancho de TILE
  mov cx, ilog2e(ANCHOTILEBYTES)
  shl bx, cl


  ; 1.3 .- Sumar
  add ax, bx
  mov di, ax	; Destination Index

  ; 2 .- Calcular SI (Source Index)
  mov cx, ilog2e(ALTOTILE * ANCHOTILEBYTES)
  shl dx, cl
  add dx, EGAIMGDATA
  mov si, dx

  ; 3 .- Copiar datos
  mov ax, es
  mov ds, ax

  mov cx, ALTOTILE
  .looprows:
  mov dx, cx
  mov cx, ANCHOTILEBYTES
  rep movsb
  mov cx, dx
  add di, WIDTHBYTES - ANCHOTILEBYTES
  loop .looprows

  .salir:
  pop bx	; Restaurar bx y ax
  pop ax
  pop si
  pop ds
  ret

initsprite.ega:
  ret

contectsprite.ega:
  ret


copiagraficos.ega:
  push bp
  mov bp, sp
  sub sp, 4   ; variables locales * 2

  ; [bp + 10] = cantidad de ciclos
  ; [bp + 8] = cantidad de palabras (2 bytes) de ancho
  ; [bp + 6] = direccion de origen a copiar
  ; [bp + 4] = pixel offset
  ; [bp + 2] = saved ip (return address)
  ; [bp] = saved bp
  ; [bp - 2] = local 1 (pixeles siguientes temporal)
  ; [bp - 4] = Copia de cantidad dee ciclos, para conteo


  mov cx, 3     ; dl = plano a copiar

  .cicloplanos:


  SelectPlaneNumber   ; Numero de plano en cl

  ; ciclo de copiado
  mov dx, cx	; dx = plano a copiar
  ;push cx
  ;push dx

  mov ax, [bp + 10]
  mov [bp - 4], ax


  ; Establecer direccion es origen y destino
  ; Origen = RAM, Destino = VRAM
  mov ax, [ega_alloc_end]
  mov di, ax    ; ES:DI => Inicio de EGA Buffer en VRAM
  mov si, [bp + 6]    ; direccion de origen a copiar

  .cicloexterno:

  ; Llenar espacio vacío de desplazamiento
  mov al, 0ffh
  mov cx, [bp + 4] ; cx = pixel offset
  shr al, cl
  not al
  mov [bp - 2], al

  mov cx, [bp + 8]	; cx = cantidad de palabras a copiar



  .ciclocopia:
  push cx

  call convierteabitplano

  ;add di, WIDTHBYTES - 2
  pop cx
  loop .ciclocopia

  mov bx, [bp + 4]  ; Pixel offset
  test bx, bx
  jz .sigpilon
  mov al, [bp-2]  ; ultimo byte almacenado
  ; Agregar color de relleno
  mov ah, 0ffh
  mov cx, [bp + 4] ; cx = pixel offset
  shr ah, cl
  or al, ah
  ;mov ax, 0ffffh
  stosb  ; Copiar a VRAM
  .sigpilon:


  mov ax, [bp - 4]
  dec ax
  mov [bp - 4], ax
  ;cmp ax, 0
  test ax, ax
  jnz .cicloexterno


  ;pop dx
  mov cx, dx
  ;pop cx
  dec cx
  jge .cicloplanos
  ;loop .cicloplanos



  ; Mejor usar di para establecer limite [ega_alloc_end]
  ; de esta forma es más simple.
  ;mov ax, [ega_alloc_end]
  ;add ax, [bp + 8]
  ;mov bx, [bp + 4]  ; Pixel offset
  ;test bx, bx
  ;jz .sigpilon2
  ;inc ax
  .sigpilon2:
  mov ax, di
  mov [ega_alloc_end], ax



  mov sp, bp
  pop bp

  ret


convierteabitplano:

  lodsw     ; AX = datos gráficos

  mov cl, dl	; cl = plano a copiar

  mov bl, al
  ;shr bl, 4   ; Procesar primero 4 bits
  shr bl, 1
  shr bl, 1
  shr bl, 1
  shr bl, 1
  shr bl, cl  ; Desplazamiento del plano actual
  and bl, 1   ; tomar solo ultimo bit
  mov bh, bl
  shl bh, 1
  or bh, bl   ; duplicar bit
  mov ch, bh  ; almacenar en ch
  shl ch, 1
  shl ch, 1   ; recorrer ch, 2 bits

  mov bl, al  ; Lo mismo, pero con siguientes 4 bits
  shr bl, cl  ; Desplazamiento del plano actual
  and bl, 1   ; tomar solo ultimo bit
  mov bh, bl
  shl bh, 1
  or bh, bl   ; duplicar bit
  or ch, bh   ; almacenar bits en ch
  shl ch, 1
  shl ch, 1   ; recorrer ch, 2 bits

  mov bl, ah
  ;shr bl, 4   ; Procesar primero 4 bits
  shr bl, 1
  shr bl, 1
  shr bl, 1
  shr bl, 1
  shr bl, cl  ; Desplazamiento del plano actual
  and bl, 1   ; tomar solo ultimo bit
  mov bh, bl
  shl bh, 1
  or bh, bl   ; duplicar bit
  or ch, bh  ; almacenar en ch
  shl ch, 1
  shl ch, 1   ; recorrer ch, 2 bits

  mov bl, ah  ; Lo mismo, pero con siguientes 4 bits
  shr bl, cl  ; Desplazamiento del plano actual
  and bl, 1   ; tomar solo ultimo bit
  mov bh, bl
  shl bh, 1
  or bh, bl   ; duplicar bit
  or ch, bh   ; almacenar bits en ch


  mov ah, ch
  xor al, al
  mov cl, [bp + 4] ; Desplazamiento en px?
  shr ax, cl
  mov bx, [bp - 2]	; Agregar pixeles desplazados
  mov [bp - 2], ax
  or ah, bl
  mov al, ah

  stosb       ; Almacenar byte en memoria de video

  ret



  ega_alloc_end:
  dw EGAIMGDATA


