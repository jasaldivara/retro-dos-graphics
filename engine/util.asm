
section .text

videomenu:


  ; 1.- Entrar en video modo 4
  mov  ah, SETVIDEOMODE   ; Establecer modo de video
  mov  al, 4      ; CGA Modo 4
  int  VIDEOBIOS   ; LLamar a la BIOS para servicios de video


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



section .data

  video_menu_title: db 'Select video mode', 0

  video_menu_cga: db '1 CGA RGBI Monitor', 0

  video_menu_composite: db '2 CGA/TANDY Composite Monitor or TV', 0

  video_menu_tandy: db '3 TANDY RGBI Monitor', 0


