
  %define VIDEOBIOS 0x10
  %define SETVIDEOMODE 0
  %define CGA4COLOR 0x04
  %define EGALORES  0x0D
  %define WIDTHPX 320d
  %define WIDTHBYTES 40d
  %define HEIGHTPX 200d

  %define MEMEGA      0xA000
  %define MEMCGAEVEN 0xB800
  %define MEMCGAODD 0xBA00

  org 100h 
 
section .text 
 
start:
  ; program code
  mov  ah, SETVIDEOMODE   ; Establecer modo de video
  mov  al, EGALORES      ; CGA 4 Colores 320 x 200
  int  VIDEOBIOS   ; LLamar a la BIOS para servicios de video


  mov ax, MEMEGA
  mov es, ax

  call drawsprite

  call esperatecla

fin:
  int 20h

ponbyte:
  ; Parametros:
  ; ax: desplazamiento
  ; dl: Valor del byte
  mov di, ax
  mov ax, MEMEGA
  mov es, ax
  mov [es:di], dl
  ret

esperatecla:

  .wl:             ; mark wl
  mov ah, 1        ; 0 - keyboard BIOS function to get keyboard scancode
  int 16h         ; keyboard interrupt
  jz .wl           ; if 0 (no button pressed) jump to wl
  ret

drawsprite:
  mov al, [spritey]
  mov ah, WIDTHBYTES
  mul ah
  mov bx, [spritex]
  mov dl, bl
  and dl, 00000111b
  shr bx, 3
  add ax, bx
  mov bx, ax
  mov di, ax
  mov ax, sprite
  mov si, ax

  mov bh, 00001000b
  mov bl, dl

  .planos:

  mov dx, 3C4h       ; address of sequencer address register
  mov al, 2h         ; index of map mask register
  out dx, al

  mov dx, 3C5h       ; address of sequencer data register
  mov al, bh  ; turn on the 'red' and 'intense' planes
  out dx, al

  mov cx, 8
  .rows:
  mov dx, cx
  mov cl, bl
  lodsb
  mov ah, al
  xor al, al
  shr ax, cl
  stosw
  add di, WIDTHBYTES - 2
  mov cx, dx
  loop .rows
  sub di, (WIDTHBYTES * 8)
  shr bh, 1
  ;test bh, bh
  jnc .planos
  ;jmp fin
  ret

section .data
  ; program data
 
  msg  db 'Hola amigos!!'
  crlf db 0x0d, 0x0a
  endstr db '$'

  spritex:
  dw  40d
  spritey:
  dw 92d

  sprite:

  db 00000000b
  db 01111110b
  db 01111110b
  db 01111110b
  db 01111110b
  db 01111110b
  db 01111110b
  db 00000000b

  db 00000000b
  db 00010000b
  db 00001100b
  db 00110000b
  db 00001110b
  db 01110000b
  db 00011100b
  db 00010000b

  db 00000000b
  db 00111100b
  db 00001110b
  db 01100100b
  db 00111100b
  db 01100110b
  db 11111000b
  db 00011000b

  db 00000000b
  db 00111110b
  db 11100000b
  db 00011110b
  db 11111000b
  db 00011110b
  db 11111000b
  db 00001100b

section .bss
  ; uninitialized data

