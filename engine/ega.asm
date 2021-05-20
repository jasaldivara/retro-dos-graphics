; Copyright 2021 Jesús Abelardo Saldívar Aguilar




  ; %define EGAIMGDATA  0x2000
  ; %define EGAIMGDATA  (WIDTHBYTES * HEIGHTPX)
  %define EGAIMGDATA  0x4000

  %macro WaitDisplayEnable 0

  MOV	DX, 03DAH

  %%WaitLoop:
	in	al, dx
	and	al, 1
	jnz	%%WaitLoop

  %endmacro

  %macro SelectPlaneNumber 0
  ; Colocar en cl numero de plano
  ; Destruye DX y AL

  mov dx, 3C4h       ; address of sequencer address register
  mov al, 2h         ; index of map mask register
  out dx, al

  mov dx, 3C5h        ; address of sequencer data register
  mov al, 1          ; Activar el plano actual
  shl al, cl
  out dx, al

  %endmacro


  %macro SelectAllPlanes 0
  ; Destruye DX y AL

  mov dx, 3C4h       ; address of sequencer address register
  mov al, 2h         ; index of map mask register
  out dx, al

  mov dx, 3C5h        ; address of sequencer data register
  mov al, 00001111b          ; Activar todos los planos
  out dx, al

  %endmacro

  %macro SetGraphicsControllerRegister 2

  mov dx, 3CEh       ; address of graphics controller register
  mov al, %1         ; index of register
  out dx, al

  mov dx, 3CFh
  mov al, %2         ; value of register
  out dx, al

  %endmacro

  %macro SetAttributeControllerRegister 2

  mov dx, 3C0h       ; address of graphics controller register
  mov al, %1         ; index of register
  out dx, al

  ;mov dx, 3C0h
  mov al, %2         ; value of register
  out dx, al

  %endmacro


  %macro SetCRTControllerRegister 2

  mov dx, 3D4h
  mov al, %1	; Numero de registro a cambiar
  out dx, al

  mov dx, 3D5h
  mov al, %2	; Nuevo valor del registro
  out dx, al

  %endmacro

  %macro CopiaConvierteGraficosEGA 4

  ; %1 = cantidad de ciclos
  ; %2 = cantidad de palabras (2 bytes) de ancho
  ; %3 = direccion de origen a copiar
  ; %4 = pixel offset

  mov ax, %1
  push ax
  mov ax, %2
  push ax
  mov ax, %3
  push ax
  mov ax, %4
  push ax
  call copiagraficos.ega
  add sp, 8	; Restablecer pila

  %endmacro


drawmap.ega:
  ret

drawsprite.ega:
  ret

borrasprite.ega:
  ret

drawtile.ega:
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


