
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


  ; inicia musica
  ; mov bx, 4554d
  ; setFreqSpeak
  ; SpeakerOn

  mov ax, partitura
  mov word [iniciopart], ax

  ; 2 .- Registrar nueva rutina de interrupción del teclado
  mov     al, 1Ch
  mov     ah, 25h
  mov     bx, cs
  mov     ds, bx
  mov     dx, rutinatimer
  int     21h


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


rutinatimer:

  ; 1.- cargar segmento de datos (igual al segmento de codigo)
  mov bx, cs
  mov ds, bx

  .carganota:
  ; 2.- cargar posicion de nota actual en la partitura
  mov word dx, [iniciopart]
  mov si, dx
  mov word bx, [notapos]
  shl bx, 1
  shl bx, 1
  lea si, [si + bx]
  lodsw

  ; 3.- Verificar que no sea fin de partitura
  test ax, ax
  jnz .sig1
  	; 3.1 Si es el fin de partitura, volver a comenzar
  xor bx, bx
  mov word [notapos], bx
  mov word [notatick], bx
  jmp .carganota

  .sig1:

  ; 4.- Verificar timer tick
  mov word bx, [notatick]
  test bx, bx
  jnz .sig2
  	; Si tick es cero, tocar nota nueva
  	lodsw
  	test ax, ax
  	jnz .sonido
  		; si nota (ax) es cero, apagar speaker
  		SpeakerOff
  		jmp .inctick
  	.sonido:
  		; Si no es cero, reproducir en dicha frecuencia
  		mov bx, ax
  		setFreqSpeak
  		SpeakerOn
  		jmp .inctick
  .sig2:

  ; Verificar si termina nota actual
  cmp ax, bx
  jge .inctick

  mov word ax, [notapos]
  inc ax
  mov word [notapos], ax
  xor bx, bx
  mov word [notatick], bx
  jmp .carganota

  .inctick:
  mov word bx, [notatick]
  inc bx
  mov word [notatick], bx

  .fin:
  iret

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
  partitura:	; Si la nota es cero: Guardar silencio

  dw	4, 4554
  dw	2, 4058

  dw     1,7231
  dw     1,6449
  dw     2,6818

  dw	4, 3615
  dw	2, 4058

  dw     1,7231
  dw     1,6449
  dw     2,6818

  dw	4, 2875
  dw	2, 3224

  dw     1,7231
  dw     1,6449
  dw     2,6818

  dw	4, 2415
  dw	2, 2875

  dw     1,7231
  dw     1,6449
  dw     2,6818

  dw	0, 0		; Si la duración es cero: Fin de la música

