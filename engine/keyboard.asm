
section .text

kb_int_new:
  ; Keyboard Interrupt Handler
  sti ; ??? ¿habilitar interrupciones?
  ; Guardar registros
  push ax
  push bx
  push cx
  push dx
  push si
  push di
  push ds
  push es


  mov ax, cs  ; Usar segemtno actual del programa, basado en cs
  mov ds, ax
  mov es, ax

  in al, 60h  ; obtener scancode
  mov bl, al  ; respaldarlo en otro registro

  in  al, 61h
  mov ah, al	;Save keyboard status
  or  al, 80h	;Disable
  out 61h, al
  mov al, ah	;Enable (If it was disabled at first, you wouldn't
  out 61h, al	; be doing this anyway :-)

  xchg ax, bx

  ; Revisar si es tecla presionada o liberada
  test al, 80h  ; Codigo de tecla liberada
  jnz .k_liberada

  .k_presionada:
  mov ah, 1 ; Valor 1 para tecla presionada

  jmp .cualtecla

  .k_liberada:
  and al, 7fh ; Conservar scancode de tecla, desechando bit de presionada o liberada
  mov ah, 0 ; valor 0 para tecla liberada

  .cualtecla:
  cmp al, KB_ESC
  jne .sig1
  mov bx, tecla_esc
  jmp .guardar
  .sig1:
  cmp al, KB_LEFT
  jne .sig2
  mov bx, tecla_left
  jmp .guardar
  .sig2:
  cmp al, KB_RIGHT
  jne .sig3
  mov bx, tecla_right
  jmp .guardar
  .sig3:
  cmp al, KB_UP
  jne .sig4
  mov bx, tecla_up
  jmp .guardar
  .sig4:
  cmp al, KB_DOWN
  jne .sig5
  mov bx, tecla_down
  jmp .guardar
  .sig5:
  cmp al, KB_SALTA
  jne .sig6
  mov bx, tecla_salta
  jmp .guardar
  .sig6:
  cmp al, KB_ACCION
  jne .sig7
  mov bx, tecla_accion
  jmp .guardar
  .sig7:


  jmp .salida

  .guardar:
  ;mov di, bx
  mov byte [bx], ah  ; Almacenar valor 1 ó 0 en registro de tecla correspondiente


  .salida:

  ;mov byte [tecla_esc], 11b
  cli ; ??? ¿Deshabilitar interrupciones

  ; Enviar señal EOI (End of Interrupt)
  mov     al,20h
  out     20h,al

  ; reestablecer registros
  pop es
  pop ds
  pop di
  pop si
  pop dx
  pop cx
  pop bx
  pop ax
  iret


kbcontrolfunc:
  xor al, al
  mov ah, [tecla_left]
  test ah, ah
  jz .sig1
  or al, 00000111b
  .sig1:
  mov ah, [tecla_right]
  test ah, ah
  jz .sig2
  or al, 00000011b
  .sig2:
  mov ah, [tecla_salta]
  test ah, ah
  jz .sig3
  or al, ABTN
  .sig3:
  mov ah, [tecla_accion]
  test ah, ah
  jz .sig4
  or al, BBTN
  .sig4:

  ret

section .data



  ; Estado de las teclas:
  tecla_esc: db 0
  tecla_up: db 0
  tecla_down: db 0
  tecla_left: db 0
  tecla_right: db 0
  tecla_salta: db 0
  tecla_accion: db 0

