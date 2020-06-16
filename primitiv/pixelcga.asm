
  %define VIDEOBIOS 0x10
  %define SETVIDEOMODE 0
  %define CGA4COLOR 0x04
  %define WIDTHPX 320d
  %define PXB 4   ; Pixeles por byte
  %assign PYTERPERSCAN (WIDTHPX * PXB)

  %define MEMCGAEVEN 0xB800
  %define MEMCGAODD 0xBA00

  org 100h 
 
section .text 
 
start:
  ; program code
  mov  ah, SETVIDEOMODE   ; Establecer modo de video
  mov  al, CGA4COLOR      ; CGA 4 Colores 320 x 200
  int  VIDEOBIOS   ; LLamar a la BIOS para servicios de video

  mov cx, 100
  mov ax, 0
  miloop:

  push cx
  push ax
  mov bx, ax  
  mov ch, 0x01
  call ponpixelcga4col
  pop ax
  pop cx
  inc ax
  loop miloop

  mov ax, 50
  mov bx, 100
  mov ch, 1
  call  ponpixelcga4col

  mov ax, 51
  mov bx, 101
  mov ch, 2
  call  ponpixelcga4col
  
  

  call esperatecla

fin:
  int 20h

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
 
section .bss
  ; uninitialized data

