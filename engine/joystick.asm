
section .text


jscontrolfunc:

  call readjoystickpos

  xor cl, cl

  .cmplx:
  .cmplx1:
  mov ax, [js1xcount]
  mov bx, [js1xtb1]

  cmp ax, bx
  jge .cmplx2

  or cl, 00000111b
  jmp .btn

  .cmplx2:

  mov bx, [js1xtb2]
  cmp ax, bx
  jge .cmplx3

  or cl, 00000110b
  jmp .btn

  .cmplx3:

  mov bx, [js1xtb3]
  cmp ax, bx
  jge .cmpgx

  or cl, 00000101b
  jmp .btn

  .cmpgx:
  .cmpgx1:
  mov bx, [js1xte3]
  cmp ax, bx
  jle .cmpgx2

  or cl, 00000011b
  jmp .btn

  .cmpgx2:
  mov bx, [js1xte2]
  cmp ax, bx
  jle .cmpgx3

  or cl, 00000010b
  jmp .btn

  .cmpgx3:
  mov bx, [js1xte1]
  cmp ax, bx
  jle .btn

  or cl, 00000001b
  ;jmp .btn

  .btn:
  
  readJoystick
  test al, JS1A
  jnz .bbtn

  or cl, ABTN

  .bbtn:

  test al, JS1B
  jnz .return

  or cl, BBTN

  .return:
  mov al, cl

ret


calibrateJoystick:


  mSetVideoMode 3	; CGA Modo 3: Texto a color, 80 x 25.

  ; Disable blinking
  mov dx, 03D8h
  mov al, 00001001b
  out dx, al

  EsperaTiempo

  lea bx, [msgcalibra]
  mEscribeStringzColor  00001111b, 2, 1

  EsperaTiempo

  lea bx, [msgjbegin]
  mEscribeStringzColor  00001111b, 2, 3

  call ciclomuestrajoystick

  call readjoystickpos

  mov ax, [js1ycount]
  mov [js1ybegin], ax

  mov ax, [js1xcount]
  mov [js1xbegin], ax

  EsperaTiempo

  mBorraTexto 80d, 0, 3

  EsperaTiempo

  lea bx, [msgsuelte]
  mEscribeStringzColor  00001111b, 2, 9

  call esperajoystick

  EsperaTiempo

  mBorraTexto 80d, 0, 9

  EsperaTiempo

  lea bx, [msgjcenter]
  mEscribeStringzColor  00001111b, 2, 3

  call ciclomuestrajoystick

  call readjoystickpos

  mov ax, [js1ycount]
  mov [js1ycenter], ax

  mov ax, [js1xcount]
  mov [js1xcenter], ax

  EsperaTiempo

  mBorraTexto 80d, 0, 3

  EsperaTiempo

  lea bx, [msgsuelte]
  mEscribeStringzColor  00001111b, 2, 9


  call esperajoystick

  EsperaTiempo

  mBorraTexto 80d, 0, 9

  EsperaTiempo

  lea bx, [msgjend]
  mEscribeStringzColor  00001111b, 2, 3


  call ciclomuestrajoystick

  call readjoystickpos

  mov ax, [js1ycount]
  mov [js1yend], ax

  mov ax, [js1xcount]
  mov [js1xend], ax

  EsperaTiempo

  mBorraTexto 80d, 0, 3

  EsperaTiempo

  lea bx, [msgsuelte]
  mEscribeStringzColor  00001111b, 2, 9


  call esperajoystick

  EsperaTiempo

  call calculalimites

  ret

calculalimites:

  ; Calcular en X

  mov ax, [js1xbegin]
  mov bx, [js1xcenter]
  mov cx, ax
  add cx, bx
  shr cx, 1
  mov [js1xtb2], cx
  add ax, cx
  shr ax, 1
  mov [js1xtb1], ax
  mov ax, bx
  add ax, cx
  shr ax, 1
  mov [js1xtb3], ax

  mov ax, [js1xend]
  mov cx, ax
  add cx, bx
  shr cx, 1
  mov [js1xte2], cx
  add bx, cx
  shr bx, 1
  mov [js1xte1], bx
  add ax, cx
  shr ax, 1
  mov [js1xte3], ax


  ; Calcular en Y

  mov ax, [js1ybegin]
  mov bx, [js1ycenter]
  mov cx, ax
  add cx, bx
  shr cx, 1
  mov [js1ytb2], cx
  add ax, cx
  shr ax, 1
  mov [js1ytb1], ax
  mov ax, bx
  add ax, cx
  shr ax, 1
  mov [js1ytb3], ax

  mov ax, [js1yend]
  mov cx, ax
  add cx, bx
  shr cx, 1
  mov [js1yte2], cx
  add bx, cx
  shr bx, 1
  mov [js1yte1], bx
  add ax, cx
  shr ax, 1
  mov [js1yte3], ax

ret

ciclomuestrajoystick:

  .mainloop:

  readJoystick

  push ax

  test al, JS1A

  jnz .noa

  pop ax

  ret

  mov bh, 00001011b
  mov bl, 'A'

  jmp .escribea

  .noa:

  mov bh, 00001111b
  mov bl, 0

  .escribea:

  mov dh, 5
  mov dl, 6
  call escribecaracter

  .sig1:

  pop ax

  test al, JS1B
  jnz .nob

  mov bh, 00001011b
  mov bl, 'B'
  mov dh, 5
  mov dl, 8
  call escribecaracter

  jmp .sig2

  .nob:

  mov bh, 00001111b
  mov bl, 0
  mov dh, 5
  mov dl, 8
  call escribecaracter

  .sig2:

  call readjoystickpos

  mov bx, [js1ycount]
  mov dh, 5
  mov dl, 15
  call escribepalabradecimal

  mov bx, [js1xcount]
  mov dh, 5
  mov dl, 22
  call escribepalabradecimal

  VSync

  jmp .mainloop

  .return:

  ret

readjoystickpos:

  xor ax, ax
  mov [js2ycount], ax
  mov [js2xcount], ax
  mov [js1ycount], ax
  mov [js1xcount], ax

  cli	; Deshabilitar interrupciones

  mov dx, JOYSTICKPORT
  out dx, al

  .jsloop:
  in al, dx

  test al, JS2Y
  jz .sig1
  inc word [js2ycount]

  .sig1:
  test al, JS2X
  jz .sig2
  inc word [js2xcount]

  .sig2:
  test al, JS1Y
  jz .sig3
  inc word [js1ycount]

  .sig3:
  test al, JS1X
  jz .sig4
  inc word [js1xcount]

  .sig4:
  test al, ( JS2Y | JS2X | JS1Y | JS1X )
  jnz .jsloop


  sti	; Habilitar interrupciones
  ret

esperajoystick:

  .preloop:

  mov cx, 9

  .loop:

  readJoystick

  test al, JS1A

  jz .preloop

  VSync

  loop .loop

  ret


section .data


js2ycount:	dw 0000h
js2xcount:	dw 0000h
js1ycount:	dw 0000h
js1xcount:	dw 0000h

  ; Joystick calibration

js1xbegin:   dw 1d
js1xtb1:      dw 5d
js1xtb2:      dw 10d
js1xtb3:      dw 15d
js1xcenter:  dw 20d
js1xte1:      dw 25d
js1xte2:      dw 30d
js1xte3:      dw 35d
js1xend:     dw 40d

js1ybegin:   dw 1d
js1ytb1:      dw 5d
js1ytb2:      dw 10d
js1ytb3:      dw 15d
js1ycenter:  dw 20d
js1yte1:      dw 25d
js1yte2:      dw 30d
js1yte3:      dw 35d
js1yend:     dw 40d

msgcalibra: db 'Joystick Calibration', 0x00
msgsuelte: db 'Release joystick A button', 0x00
msgjbegin:     db 'Hold joystick on TOP LEFT position and press A button', 0x00   ; message
msgjcenter:     db 'Hold joystick on CENTER position and press A button', 0x00   ; message
msgjend:     db 'Hold joystick on BOTTOM RIGHT position and press A button', 0x00   ; message
