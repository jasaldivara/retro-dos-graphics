
section .text

spritecollisions:
  ; parametros:
  ; DS:BP => Sprite
  ; Mapa? TODO: obtener como parámetro

  ; 0 .- Revisar que no se salga

  ; 0.1 .- horizontal

  mov bx, [ds:bp + SPRITE.nx]
  mov cx, bx
  add cx, [ds:bp + SPRITE.pxw]
  cmp cx, ( MAPWIDTH * ANCHOTILE )
  jng .outxl

  mov ah, RIGHT
  call [ds:bp + SPRITE.ctrlout]
  jmp .noutx

  .outxl:
  cmp bx, 0
  jnl .noutx

  mov ah, LEFT
  call [ds:bp + SPRITE.ctrlout]

  .noutx:

  ; 0.2 .- Vertical


  ; 1.1.- revisar que no se salga
  mov bx, [ds:bp + SPRITE.ny]
  mov dx, HEIGHTPX
  sub dx, [ds:bp + SPRITE.h]

  cmp bx, dx
  jng .outyu

  mov ah, DOWN
  call [ds:bp + SPRITE.ctrlout]

  jmp .nouty

  .outyu:
  cmp bx, 0
  jnl .nouty

  mov ah, UP
  call [ds:bp + SPRITE.ctrlout]

  .nouty:


  mov bx, map1
  ; mov si, bx
  mov di, bx

  .vertical:
  mov bh, [ds:bp + SPRITE.y]
  mov bl, [ds:bp + SPRITE.ny]
  cmp bh, bl
  je .horizontal	; Si y == ny, es que no hay movimiento vertical
  ja .movarriba
  .movabajo:
  mov al, [ds:bp + SPRITE.h]
  dec al
  add bh, al
  add bl, al
  NYT bh
  NYT bl
  cmp bh, bl
  jge .horizontal
  inc bh
  .loopnivelabajo:
  mov al, bh	; multiplicar nivel del tile Y
  mov ah, MAPWIDTH
  mul ah
  ; xor dx, dx
  mov dx, [ds:bp + SPRITE.nx]
  NXT dx
  mov si, di
  add ax, dx
  add si, ax

  mov cx, [ds:bp + SPRITE.nx]
  add cx, [ds:bp + SPRITE.pxw]
  dec cx
  NXT cx
  .looptileabajo:
  mov ah, DOWN
  lodsb
  call [ds:bp + SPRITE.ctrlcoll]
  inc dx
  cmp cx, dx

  jge .looptileabajo
  inc bh	; siguiente renglon/nivel
  cmp bh, bl
  jle .loopnivelabajo

  jmp .horizontal


  .movarriba:
  mov bh, [ds:bp + SPRITE.y]	; Estas dos lineas están de mas?
  mov bl, [ds:bp + SPRITE.ny]
  NYT bh
  NYT bl
  cmp bh, bl
  jle .horizontal
  dec bh
  .loopnivelarriba:
  mov al, bh	; Multiplicar nivel de tile Y
  mov ah, MAPWIDTH
  mul ah
  ; xor dx, dx
  mov dx, [ds:bp + SPRITE.nx]
  NXT dx
  mov si, di
  add ax, dx
  add si, ax

  mov cx, [ds:bp + SPRITE.nx]
  add cx, [ds:bp + SPRITE.pxw]
  dec cx
  NXT cx
  .looptilearriba:
  mov ah, UP
  lodsb
  call [ds:bp + SPRITE.ctrlcoll]
  inc dx
  cmp cx, dx

  jge .looptilearriba
  dec bh	; renglon / nivel arriba
  cmp bh, bl
  jge .loopnivelarriba
  ; jmp .horizontal


  .horizontal:
  mov bx, [ds:bp + SPRITE.x]
  mov dx, [ds:bp + SPRITE.nx]
  cmp bx, dx
  je .fin
  ja .movizquierda
  .movderecha:

  mov cx, [ds:bp + SPRITE.pxw]
  dec cx
  add bx, cx
  add dx, cx
  NXT bx
  NXT dx
  cmp bx, dx

  jge .fin
  inc bx
  .loopnivelderecha:
  ; Calcular SI
  mov al, [ds:bp + SPRITE.ny]
  NYT al
  mov ah, MAPWIDTH
  mul ah
  ; xor dx, dx
  add ax, bx
  mov si, di
  add si, ax
  mov cl, [ds:bp + SPRITE.ny]
  mov ch, cl
  add ch, [ds:bp + SPRITE.h]
  dec ch
  NYT cl
  NYT ch
  mov ah, RIGHT

  .looptilederecha:
  lodsb
  call [ds:bp + SPRITE.ctrlcoll]
  add si, MAPWIDTH - 1
  inc cl
  cmp ch, cl
  jge .looptilederecha
  inc bx
  cmp bx, dx
  jle .loopnivelderecha
  jmp .fin


  .movizquierda:
  NXT bx
  NXT dx
  cmp bx, dx
  jle .fin
  dec bx
  .loopnivelizquierda:
  ; Calcular SI
  mov al, [ds:bp + SPRITE.ny]
  NYT al
  mov ah, MAPWIDTH
  mul ah
  add ax, bx
  mov si, di
  add si, ax
  mov cl, [ds:bp + SPRITE.ny]
  mov ch, cl
  add ch, [ds:bp + SPRITE.h]
  dec ch
  NYT cl
  NYT ch
  mov ah, LEFT

  .looptileizquierda:
  lodsb
  call [ds:bp + SPRITE.ctrlcoll]
  add si, MAPWIDTH - 1
  inc cl
  cmp ch, cl
  jge .looptileizquierda
  dec bx
  cmp bx, dx
  jge .loopnivelizquierda
  ; jmp .fin

  .fin:
  ret

