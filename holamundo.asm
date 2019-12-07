; 16-bit COM file example
; nasm hellocom.asm -fbin -o hellocom.com
; to run in MS DOS / DosBox: hellocom.com
  org 100h 
 
section .text 
 
start:
  ; program code
  mov  dx, msg;  '$'-terminated string
  mov  ah, 09h; write string to standard output from DS:DX
  int  0x21   ; call dos services
 
  int 20h
 
section .data
  ; program data
 
  msg  db 'Hola amigos!!'
  crlf db 0x0d, 0x0a
  endstr db '$'
 
section .bss
  ; uninitialized data

