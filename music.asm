
CPU 8086

	; Music
	; programa para componer música


%define VIDEOBIOS 0x10



  ; Notas musicales
  ; Frecuencia, tercera octava
  %define _DO	131
  %define _DO#	139
  %define _RE	147
  %define _RE#	155
  %define _MI	165
  %define _FA	175
  %define _FA#	185
  %define _SOL	196
  %define _SOL#	208
  %define _LA	220
  %define _LA#	233
  %define _SI	245


  ; Teclas del teclado

  %define KB_ESC 01
  %define KB_UP 48h
  %define KB_DOWN 50h
  %define KB_LEFT 4Bh
  %define KB_RIGHT 4Dh

  ; Teclas del teclado musical

  %define KB_DO	16
  %define KB_DO#	3
  %define KB_RE	17
  %define KB_RE#	4
  %define KB_MI	18
  %define KB_FA	19
  %define KB_FA#	6
  %define KB_SOL	20
  %define KB_SOL#	7
  %define KB_LA	21
  %define KB_LA#	8
  %define KB_SI	22

  %define freqosc	1193180


  ; macro mus(n,o)
  ;
  ; n = frecuencia de la nota en tercera octava
  ; o = numero de octava que se desea
  ;
  ; Genera un numero de conteo para que el oscilador genere una frecuencia
  ; segun la nota musical y la octava que se le proporcione

  %define mus(n,o)	freqosc / (n << (o - 3))

  %macro SpeakerOn 0

  in	al, 61h
  or	al, 00000011b
  out	61h, al
  mov byte	[estadospeaker], 1

  %endmacro

  %macro SpeakerOff 0

  in	al, 61h
  and	al, 11111100b
  out	61h, al
  mov byte	[estadospeaker], 0

  %endmacro


  %macro setFreqSpeak 0

  ; Establece frecuencia del timer 2 (bocinas)
  ; bx => frecuencia

  mov al, 0b6h
  out 43h, al

  mov al, bl
  out 42h, al
  mov al, bh
  out 42h, al

  %endmacro

  org 100h


section .text

start:


  ; 2 .- Guardar Rutina de interrupcion del teclado del sistema (BIOS)
  mov     al,9h
  mov     ah,35h
  int     21h
  mov [kb_int_old_off], bx
  mov [kb_int_old_seg], es

  ; 3 .- Registrar nueva rutina de interrupción del teclado
  mov     al, 9h
  mov     ah, 25h
  mov     bx, cs
  mov     ds, bx
  mov     dx, kb_int_new
  int     21h

ciclo:

  mov al, [salir]
  test al, al
  jz ciclo


fin:
  ; 0 .- Desconectar Speaker

  SpeakerOff


  ; 2 .- Reestablecer rutina original de manejo de teclado
  mov     dx,[kb_int_old_off]
  mov     ax,[kb_int_old_seg]
  mov     ds,ax
  mov     al,9h
  mov     ah,25h
  int     21h


  ; 3 .- Salir al sistema
  int 20h

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

  cmp al, KB_DO
  jnz .sig1
  mov byte [tpresionada], KB_DO
  mov bx, mus(_DO, 4)
  setFreqSpeak
  SpeakerOn
  jmp .salida
  .sig1:

  cmp al, KB_DO#
  jnz .sig2
  mov byte [tpresionada], KB_DO#
  mov bx, mus(_DO#, 4)
  setFreqSpeak
  SpeakerOn
  jmp .salida
  .sig2:

  cmp al, KB_RE
  jnz .sig3
  mov byte [tpresionada], KB_RE
  mov bx, mus(_RE, 4)
  setFreqSpeak
  SpeakerOn
  jmp .salida
  .sig3:

  cmp al, KB_RE#
  jnz .sig4
  mov byte [tpresionada], KB_RE#
  mov bx, mus(_RE#, 4)
  setFreqSpeak
  SpeakerOn
  jmp .salida
  .sig4:

  cmp al, KB_MI
  jnz .sig5
  mov byte [tpresionada], KB_MI
  mov bx, mus(_MI, 4)
  setFreqSpeak
  SpeakerOn
  jmp .salida
  .sig5:

  cmp al, KB_FA
  jnz .sig6
  mov byte [tpresionada], KB_FA
  mov bx, mus(_FA, 4)
  setFreqSpeak
  SpeakerOn
  jmp .salida
  .sig6:

  cmp al, KB_FA#
  jnz .sig7
  mov byte [tpresionada], KB_FA#
  mov bx, mus(_FA#, 4)
  setFreqSpeak
  SpeakerOn
  jmp .salida
  .sig7:

  cmp al, KB_SOL
  jnz .sig8
  mov byte [tpresionada], KB_SOL
  mov bx, mus(_SOL, 4)
  setFreqSpeak
  SpeakerOn
  jmp .salida
  .sig8:

  cmp al, KB_SOL#
  jnz .sig9
  mov byte [tpresionada], KB_SOL#
  mov bx, mus(_SOL#, 4)
  setFreqSpeak
  SpeakerOn
  jmp .salida
  .sig9:

  cmp al, KB_LA
  jnz .sig10
  mov byte [tpresionada], KB_LA
  mov bx, mus(_LA, 4)
  setFreqSpeak
  SpeakerOn
  jmp .salida
  .sig10:

  cmp al, KB_LA#
  jnz .sig11
  mov byte [tpresionada], KB_LA#
  mov bx, mus(_LA#, 4)
  setFreqSpeak
  SpeakerOn
  jmp .salida
  .sig11:

  cmp al, KB_SI
  jnz .sig12
  mov byte [tpresionada], KB_SI
  mov bx, mus(_SI, 4)
  setFreqSpeak
  SpeakerOn
  jmp .salida
  .sig12:

  jmp .salida

  .k_liberada:
  and al, 7fh ; Conservar scancode de tecla, desechando bit de presionada o liberada

  test al, al
  jz .salida

  cmp al, KB_ESC
  jne .no_esc
  mov byte	[salir], 1
  jmp .salida

  .no_esc:
  mov ah, [tpresionada]
  cmp al, ah
  jne .salida

  mov byte [tpresionada], 0
  SpeakerOff


  .salida:

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


section .data
  ; program data

  timer_int_old_off: dw  0
  timer_int_old_seg: dw  0

  kb_int_old_off: dw  0
  kb_int_old_seg: dw  0

  ;  Variables para reproducir melodia
  estadospeaker:	db	0
  salir:		db	0
  tpresionada:		db	0


