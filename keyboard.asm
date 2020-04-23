
CPU 8086

  ; Keyboard
  ; Programa que muestra los códigos de escaneo de las teclas pulsadas
  ; Incluye funcion para mostrar en pantalla numeros en formato decimal

%define VIDEOBIOS 0x10
%define KBBIOS 0x16


%define KB_ESC 01

org 100h



start:

  ; mov ax, 0ffh
  ; call writedecimal
  mov bh, 0
  mov bl, 0ffh
  mov dx, una_cadena
  call writestringbios

  call teclas

fin:

  ; Salir al sistema
  int 20h


teclas:

  .looptecla:
  mov ah, 0
  int KBBIOS
  push ax

  mov bh, 0
  mov bl, 0ffh
  mov ah, 0eh
  int VIDEOBIOS

  mov al, 09h
  int VIDEOBIOS

  pop ax
  push ax
  mov al, ah
  xor ah, ah
  call writedecimal

  mov al, 0dh
  int VIDEOBIOS
  mov al, 0ah
  int VIDEOBIOS

  pop ax
  cmp ah, KB_ESC
  je .fin
  jmp .looptecla

  .fin:
  ret

writedecimal:
  ; ax => number

  xor cx, cx
  mov dl, 10d	; base 10
  .loopcifra:
  div dl
  inc cx
  push ax
  xor ah, ah
  test al, al
  jnz .loopcifra

  .escribe:
  pop ax
  mov bh, 0
  mov bl, 0ffh
  mov al, ah
  add al, 30h
  mov ah, 0eh
  int VIDEOBIOS
  loop .escribe

  ret



writestringbios:
  ; dx => zero-terminated string
  ; bh => page number
  ; bl => foreground color

  push si
  mov si, dx

  .loopchar:
  lodsb
  test al, al
  jz .salir
  mov ah, 0eh
  int VIDEOBIOS
  jmp .loopchar

  .salir:
  pop si
  ret


section .data

  una_cadena:	db "Una cadena de texto", 0dH, 0aH, 0

