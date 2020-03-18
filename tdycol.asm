CPU 8086

  %define VIDEOBIOS 0x10
  %define SETVIDEOMODE 0
  %define CGAHIRES 0x06
  %define TDYLORES 0x08
  %define PXB 4   ; Pixeles por byte

  %define MEMCGAEVEN 0xB800
  %define MEMCGAODD 0xBA00

  %define BYTESROW 80
  %assign ANCHOFRANJA 10
  %assign ALTOFRANJA 100

  org 100h

section .text

start:
  ; program code
  mov  ah, SETVIDEOMODE   ; Establecer modo de video
  mov  al, TDYLORES      ; Modo Tandy 16 Colores en Baja resolución
  int  VIDEOBIOS   ; LLamar a la BIOS para servicios de video

  mov ax, 0
  miloop:

  call poncolorcomp
  inc ax
  cmp ax, 16d
  jl miloop


  call esperatecla

fin:
  int 20h


poncolorcomp:
  push ax
  mov bx, ax

  mov dl, (ANCHOFRANJA / 2)	; Calcular coordenada x
  mul dl
  mov di, ax

  mov al, bl	; Estblecer valor de bytes a escribir
  mov cl, 4
  shl al, cl
  or al, bl

  mov dx, MEMCGAEVEN	; Establecer banco de memoria destino
  mov es, dx

  mov cx, (ALTOFRANJA / 2)

  .looprow:
	; Escribir/dibujar pixeles en memoria de video
  push cx
  mov cx, (ANCHOFRANJA / 2)
  rep stosb

  pop cx
  add di, (BYTESROW - ((ANCHOFRANJA / 2)))
  loop .looprow

  mov dx, MEMCGAODD	; Establecer banco de memoria destino
  mov es, dx

  sub di, ((ALTOFRANJA / 2) * BYTESROW)

  mov cx, (ALTOFRANJA / 2)

  .looprow2:
	; Escribir/dibujar pixeles en memoria de video
  push cx
  mov cx, (ANCHOFRANJA / 2)
  rep stosb

  pop cx
  add di, (BYTESROW - ((ANCHOFRANJA / 2)))
  loop .looprow2

  mov dx, MEMCGAODD	; Establecer banco de memoria destino
  mov es, dx


  pop ax
  ret


ponbyte:
  ; Parametros:
  ; ax: desplazamiento
  ; dl: Valor del byte
  mov di, ax
  mov ax, MEMCGAEVEN
  mov es, ax
  mov [es:di], dl
  ret


esperatecla:

  wl:             ; mark wl
  mov ah,0        ; 0 - keyboard BIOS function to get keyboard scancode
  int 16h         ; keyboard interrupt
  ; jz wl           ; ESTO NO FUNCINA EN LLAMADA 0. USAR SOLO EN LLAMADA 1
  ret

section .data
  ; program data


section .bss
  ; uninitialized data

