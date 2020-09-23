
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

  ; Constantes del juego

  %define VEL 2
  %define ANCHO 8


  ; vsync: Esperar retrazo vertical
  %macro VSync 0

  MOV	DX, 03DAH

  %%Retrace1:
	IN	AL,DX			; AL := Port[03DAH]
	TEST	AL,8			; Is bit 3 set?
	JZ	%%Retrace1		; No, continue waiting

	%%Retrace2:				;	IN	AL,DX			
	IN	AL,DX		; AL := Port[03DAH]
	TEST	AL,8			; Is bit 3 unset?
	JNZ	%%Retrace2		; No, continue waiting

  %endmacro


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

  .frame:

  ; 0 .- VSync

  VSync

  call clearsprite

  ; 1.- calcular x
  mov ax, [spritex]
  mov dx, VEL
  mov bh, [deltax]
  test bh, bh
  jz .sig1
  add ax, dx
  jmp .sig2
  .sig1:
  sub ax, dx
  .sig2:
  cmp ax, WIDTHPX - ANCHO
  jng .sig3
  mov ax, WIDTHPX - ANCHO
  mov bh, 0
  mov [deltax], bh
  .sig3:
  cmp ax, 0
  jnl .sig4
  mov ax, 0
  mov bh, 1
  mov [deltax], bh
  .sig4:
  mov [spritex], ax


  ; 1.- calcular y
  mov ax, [spritey]
  mov dx, VEL
  mov bh, [deltay]
  test bh, bh
  jz .sig5
  add ax, dx
  jmp .sig6
  .sig5:
  sub ax, dx
  .sig6:
  cmp ax, HEIGHTPX - ANCHO
  jng .sig7
  mov ax, HEIGHTPX - ANCHO
  mov bh, 0
  mov [deltay], bh
  .sig7:
  cmp ax, 0
  jnl .sig8
  mov ax, 0
  mov bh, 1
  mov [deltay], bh
  .sig8:
  mov [spritey], ax

  call drawsprite

  ; y.- Revisar teclado
  mov ah, 1   ; "Get keystroke status"
  int 16h
  jz .frame

  ;call esperatecla
  mov ah, 0
  int 16h

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

  mov dx, 3C5h        ; address of sequencer data register
  mov al, bh          ; Activar el plano actual
  out dx, al

  mov cx, 8
  .rows:
  mov dx, cx
  mov cl, bl
  lodsb
  xor ah, ah
  ror ax, cl
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

clearsprite:
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

  .planos:

  mov dx, 3C4h       ; address of sequencer address register
  mov al, 2h         ; index of map mask register
  out dx, al

  mov dx, 3C5h        ; address of sequencer data register
  mov al, 00001111b   ; Activar los cuatro planos
  out dx, al

  mov cx, 8   ; 8 renglones
  .rows:
  mov dx, cx  ; dx = renglones restantes
  xor ax, ax
  stosw
  add di, WIDTHBYTES - 2
  mov cx, dx
  loop .rows

  ret


section .data
  ; program data
 
  msg  db 'Hola amigos!!'
  crlf db 0x0d, 0x0a
  endstr db '$'

  spritex:
  dw  42d
  spritey:
  dw 92d

  deltax:
  db 1
  deltay:
  db 1

  align   8,db 0

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

