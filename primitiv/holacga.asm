
  %define VIDEOBIOS 0x10
  %define SETVIDEOMODE 0
  %define CGA4COLOR 0x04

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
  mov ax, 100
  miloop:

  mov dl, 0x1E
  push ax
  call ponbyte
  pop ax
  inc ax
  loop miloop

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

esperatecla:

  wl:             ; mark wl
  mov ah, 1        ; 0 - keyboard BIOS function to get keyboard scancode
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

