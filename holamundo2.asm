; hello3-DOS.asm - single-segment, 16-bit "hello world" program
;
; Use DOS 2.0's service 40 to output a length-delimited string.
;
; assemble with "nasm -f bin -o hi.com hello3-DOS.asm"

    %define STDOUT 1
    %define WRITEFILE 0x40
    %define TERMPROG 0x4c
    %define DOSSERV 0x21

    org  0x100          ; .com files always start 256 bytes into the segment

; int 21h needs...
    mov  dx, msg        ; message's address in dx
    mov  cx, len
    mov  bx, STDOUT          ; Device/handle: standard out (screen)
    mov  ah, WRITEFILE       ; ah=0x40 - "Write File or Device"
    int  DOSSERV           ; call dos services

    mov  ah, TERMPROG       ; "terminate program" sub-function
    int  DOSSERV           ; call dos services

msg     db 'Hola de nuevo, joajoajoajoa!', 0x0d, 0x0a, 'Desde MS-DOS 2.0 o posterior ;)', 0x0d, 0x0a   ; message
len     equ $ - msg     ;msg length

