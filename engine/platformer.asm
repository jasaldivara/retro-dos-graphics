
section .text

sphysicsframe:
  ; Parametros:
  ; BP => sprite

  ; 1.- Leer el control X


  xor bx, bx
  mov bl, al
  and bl, 00000011b
  test al, 00000100b
  jz .endxsign
  neg bx
  .endxsign:

  mov dx, [ds:bp + SPRITEPHYS.vuelox]
  sal bx, 1
  sal bx, 1
  sal bx, 1
  cmp dx, bx
  je .endvx
  jg .decvx
  inc dx
  jmp .endvx
  .decvx:
  dec dx
  .endvx:

  mov [ds:bp + SPRITEPHYS.vuelox], dx
  sar dx, 1
  sar dx, 1
  sar dx, 1


  .calcx:    ; 2.- calcular x

  mov cx, [ds:bp + SPRITE.x]
  add cx, dx
  mov [ds:bp + SPRITE.nx], cx

  .saltar:
  ; ¿está presionada esta tecla?
  test al, ABTN
  jz .calcdy

  ; mov al, [ds:bp + SPRITEPHYS.parado] ; Tiene que estar parado para poder saltar
  ; test al, al
  ; jnz .sisaltar


  mov ah, [ds:bp + SPRITEPHYS.saltoframes] ; Si no está parado, pero aún tiene fuerza para saltar
  test ah, ah
  jz .calcdy

  .sisaltar:
  ; Ahora sí: Saltar porque estamos parados o tenemos fuerza para saltar y con la tecla saltar presionada
  mov bx, -FUERZASALTO
  mov [ds:bp + SPRITEPHYS.deltay], bx
  ; mov bx, 0
  dec ah
  mov [ds:bp + SPRITEPHYS.saltoframes], ah
  xor ah, ah
  mov [ds:bp + SPRITEPHYS.parado], ah


  .calcdy:  ; 2.- Calcular delta Y
  mov dx, [ds:bp + SPRITEPHYS.deltay]
  add dx, GRAVEDAD
  mov [ds:bp + SPRITEPHYS.deltay], dx

  .calcy:      ; 3.- calcular y

  mov ax, [ds:bp + SPRITE.y]
  mov bx, [ds:bp + SPRITEPHYS.deltay]
  add ax, bx
  mov [ds:bp + SPRITE.ny], ax
  ; mov [ds:bp + SPRITEPHYS.deltay], bx

  ; Fin de logica del jugador por frame
  ; call spritecollisions
  jmp spritecollisions
  ; ret

animphysspriteframe:

  xor dx, dx

  mov ah, [ds:bp + SPRITEPHYS.vuelox]
  test ah, 11111000b
  jz .fincamina
  inc dl
  .fincamina:

  test al, 00000011b
  jz .sig00
  test al, 00000100b
  jz .sig0
  mov byte [ds:bp + ANIMSPRITEPHYS.direccion], 1
  jmp .sig00
  .sig0:
  mov byte [ds:bp + ANIMSPRITEPHYS.direccion], 0
  .sig00:

  xor bx, bx
  mov ah, [ds:bp + ANIMSPRITEPHYS.direccion]

  test ah, ah
  jnz .sig1
  add bh, 9
  .sig1:

  test al, ABTN
  jnz .saltar
  mov bl, [ds:bp + SPRITEPHYS.parado]
  test bl, bl
  jz .saltar

  .nosaltar:
  test dl, dl
  jz .dibujar
  mov dh, [ds:bp + ANIMSPRITEPHYS.aframecount]
  inc dh
  cmp dh, 8
  jl .sig2
  xor dh, dh
  .sig2:
  mov [ds:bp + ANIMSPRITEPHYS.aframecount], dh
  jmp .dibujar

  .saltar:
  mov dh, 8

  .dibujar:
  add bh, dh
  mov [ds:bp + SPRITE.ssframe], bh	; PRECAUCION: Usando solo 8 bits

  jmp sphysicsframe
  ; ret


spritephyscol:
  ; AH => Direccion
  ; AL => Tile
  test al, al
  jnz .nozero
  ret


  .nozero:
  test ah, DOWN
  jnz .coldown
  test ah, UP
  jnz .colup
  test ah, RIGHT
  jnz .colright

  .colleft:

  push bx
  PXT bx
  add bx, ANCHOTILE
  mov [ds:bp + SPRITE.nx], bx
  mov word [ds:bp + SPRITEPHYS.vuelox], 0
  pop bx

  .return:
  ret

  .coldown:
  mov ah, bh
  PYT ah
  sub ah, [ds:bp + SPRITE.h]
  mov [ds:bp + SPRITE.ny], ah
  mov byte [ds:bp + SPRITEPHYS.parado], JUMPFRAMES
  mov byte [ds:bp + SPRITEPHYS.saltoframes], JUMPFRAMES
  mov word [ds:bp + SPRITEPHYS.deltay], 0

  ret

  .colup:
  mov ah, bh
  PYT ah
  add ah, ALTOTILE
  mov [ds:bp + SPRITE.ny], ah
  ; mov byte [ds:bp + SPRITEPHYS.parado], 0
  mov byte [ds:bp + SPRITEPHYS.saltoframes], 0
  mov word [ds:bp + SPRITEPHYS.deltay], 0

  ret

  .colright:

  push bx
  PXT bx
  sub bx, [ds:bp + SPRITE.pxw]
  mov [ds:bp + SPRITE.nx], bx
  mov word [ds:bp + SPRITEPHYS.vuelox], 0
  ; Activar lo siguiente en caso de querer rebote: (y desactivar linea de arriba)
  ; mov word dx, [ds:bp + SPRITEPHYS.vuelox]
  ; neg dx
  ; sar dx, 1
  ; mov word [ds:bp + SPRITEPHYS.vuelox], dx
  pop bx

  ret

spritephysout:
  ; AH => Direccion
  ; BX => Coordenada x o y, dependiendo de AH

  test ah, DOWN
  jnz .coldown
  test ah, UP
  jnz .colup
  test ah, RIGHT
  jnz .colright

  .colleft:
  mov word [ds:bp + SPRITE.nx], 0
  mov word [ds:bp + SPRITEPHYS.vuelox], 0
  ret

  .colright:
  mov ax, ( MAPWIDTH * ANCHOTILE )
  sub ax, [ds:bp + SPRITE.pxw]
  mov [ds:bp + SPRITE.nx], ax
  mov word [ds:bp + SPRITEPHYS.vuelox], 0
  ret

  .colup:
  mov word [ds:bp + SPRITE.ny], 0
  mov word [ds:bp + SPRITEPHYS.deltay], 0
  ret

  .coldown:
  mov dx, HEIGHTPX
  sub dx, [ds:bp + SPRITE.h]
  mov [ds:bp + SPRITE.ny], dx
  mov word [ds:bp + SPRITEPHYS.deltay], 0
  mov word [ds:bp + SPRITEPHYS.saltoframes], JUMPFRAMES


  ret


  ; IA Basic Platformer Routines:


iabasiccontrol:
  mov al, [ds:bp + SPRITE.iavars]
  mov al, ABTN
ret

iabasiccoll:

  test al, al
  jz .sig2
  test ah, LEFT
  jz .sig1
  mov byte [ds:bp + SPRITE.iavars], 00000001b
  .sig1:
  test ah, RIGHT
  jz .sig2
  mov byte [ds:bp + SPRITE.iavars], 00000101b
  .sig2:
  ; call spritephyscol
  jmp spritephyscol
  ; ret

