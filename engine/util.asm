
section .text

videomenu:


  ; 1.- Entrar en video modo 4
  mSetVideoMode 4

  mov dh, 1
  mov dl, 10
  mov bx, video_menu_title
  mov cx, 1
  call writestring

  mov dh, 8
  mov dl, 1
  mov bx, video_menu_cga
  mov cx, 3
  call writestring

  mov dh, 10
  mov dl, 1
  mov bx, video_menu_composite
  mov cx, 3
  call writestring

  mov dh, 12
  mov dl, 1
  mov bx, video_menu_tandy
  mov cx, 3
  call writestring

  .leeteclado:
  mov ah, 0
  int 16h

  cmp al, '1'
  jne .nocga
  mov ah, SETVIDEOMODE
  mov al, 4
  int VIDEOBIOS

  ; Establecer paleta de colores
  mov dx, 03D9h
  mov al, 00011011b
  out dx, al

  mov byte [colorbackground], 0


  ret
  .nocga:

  cmp al, '2'
  jne .nocomposite
  mov ah, SETVIDEOMODE
  mov al, CGA6
  int VIDEOBIOS

  ; Entrar en modo de video compuesto
  mov dx, 03D8h
  mov al, 00011010b
  out dx, al

  ret
  .nocomposite:

  cmp al, '3'
  jne .notandy
  mov ah, SETVIDEOMODE
  mov al, 8
  int VIDEOBIOS

  mov bx, tilesgraphics
  mov cx, (endtilesgraphics - tilesgraphics)
  call conviertecomposite2tandy

  mov bx, spritesgraphics
  mov cx, (endspritesgraphics - spritesgraphics)
  call conviertecomposite2tandy

  mov bx, colorbackground
  mov cx, 1
  call conviertecomposite2tandy

  ret
  .notandy:

  jmp .leeteclado


writestring:
  ; dh => row
  ; dl => col
  ; bx => zero-terminated string
  ; cl => Color

  ; 0.- Respaldar registros
  push si
  mov si, bx
  mov bl, cl
  xor bh, bh

  ; 1.- Establecer posición del cursor
  .loopchar:
  mov ah, 2
  int VIDEOBIOS

  ; 2.- Escribir caracteres

  lodsb
  test al, al
  jz .salir
  mov ah, 10d
  mov cx, 1
  int VIDEOBIOS
  inc dl
  jmp .loopchar

  .salir:
  pop si
  ret


inputMenu:

  .init:

  mSetVideoMode 3

  lea bx, [input_menu_title]
  mEscribeStringzColor  00001111b, 2, 1

  lea bx, [input_menu_keyboard]
  mEscribeStringzColor  00001111b, 2, 3

  lea bx, [input_menu_joystick]
  mEscribeStringzColor  00001111b, 2, 5

  .leeteclado:
  mov ah, 0
  int 16h

  xor ah, ah
  cmp al, '2'
  jne .return

  call calibrateJoystick

  test al, al
  jnz .init

  mov ah, 1

  .return:
  mov al, ah

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

  video_menu_title: db 'Select video mode', 0

  video_menu_cga: db '1 CGA RGBI Monitor', 0

  video_menu_composite: db '2 CGA/TANDY Composite Monitor or TV', 0

  video_menu_tandy: db '3 TANDY RGBI Monitor', 0

  input_menu_title: db 'Select input method', 0

  input_menu_keyboard: db '1 Keyboard', 0

  input_menu_joystick: db '2 Joystick', 0
