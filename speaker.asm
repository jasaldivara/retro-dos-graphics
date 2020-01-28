
CPU 8086



  org 100h


  %macro SpeakerOn 0

  in	al, 61h
  or	al, 00000011b
  out	61h, al
  mov word	[estadospeaker], 1

  %endmacro

  %macro SpeakerOff 0

  in	al, 61h
  and	al, 11111100b
  out	61h, al
  mov word	[estadospeaker], 0

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

section .text

start:


  ; 1 .- Guardar Rutina de timer del usuario 1C (Normalmente es un 'iret')
  mov     al,1Ch
  mov     ah,35h
  int     21h
  mov [timer_int_old_off], bx
  mov [timer_int_old_seg], es


  mov bx, 4554d
  setFreqSpeak
  SpeakerOn

ciclo:
  mov ah, 1   ; "Get keystroke status"
  int 16h
  jz ciclo

  mov ah, 0
  int 16h

fin:
  ; 0 .- Desconectar Speaker

  SpeakerOff

  ; 1 .- Reestablecer rutina original de timer del usuario 1C
  mov     dx,[timer_int_old_off]
  mov     ax,[timer_int_old_seg]
  mov     ds,ax
  mov     al,1Ch
  mov     ah,25h
  int     21h

  ; 2 .- Salir al sistema
  int 20h


section .data
  ; program data

  timer_int_old_off: dw  0
  timer_int_old_seg: dw  0

  ;  Variables para reproducir melodia
  notapos:	dw	0
  notatick:	dw	0
  iniciopart:	dw	0
  estadospeaker:	dw	0


  ;	duracion, nota
  musica:
  dw	8, 4554
  dw	4, 4058
  dw	4, 0		; Si la nota es cero: Guardar silencio
  dw	0, 0		; Si la duración es cero: Fin de la música

