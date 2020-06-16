
CPU 8086

  %use ifunc

  %define VIDEOBIOS 0x10
  %define SETVIDEOMODE 0
  %define CGA6 0x06
  %define WIDTHPX 160d
  %define HEIGHTPX 200d
  %define PXB 2   ; Pixeles por byte
  %assign BYTESPERSCAN (WIDTHPX / PXB)

  %define MEMCGAEVEN 0xB800
  %define MEMCGAODD 0xBA00

  %define KB_ESC 01
  %define KB_UP 48h
  %define KB_DOWN 50h
  %define KB_LEFT 4Bh
  %define KB_RIGHT 4Dh

  ; Constantes del juego

  %define GRAVEDAD 1
  %define JUMPFRAMES 14
  %define FUERZASALTO 5
  %define ANCHOSPRITE 8
  ; %define ALTOSPRITE 32
  %define ANCHOTILE 8
  %define ALTOTILE 16
  %define MAPWIDTH 20
  %define MAPHEIGHT 12

  %define BWSPRITE ( ANCHOSPRITE / PXB )  ; Ancho de Sprite en Bytes

  ; Direcciones
  ; Para controles y detección de colisiones

  %define UP		00001000b
  %define DOWN		00000100b
  %define LEFT		00000010b
  %define RIGHT		00000001b

  ; data structures

  ; Game specific constants



  struc SPRITESHEET
    .framescount:	resw 1	; Cantidad de frames que contiene el sprite
    .h			resw 1
    .w			resw 1
    .gr0:		resw 1
    .gr1:		resw 1
    .4colgr:		resw 1
    .16colgr:		resw 1
  endstruc

  struc SPRITE

    .frame:	resw 1	; Pointer to function defining per frame logic
    .control:	resw 1  ; Pointer to control function. Could be keyboard or joystick player, or A.I.
    .ctrlcoll:	resw 1	; Pointer to controll collision event. Called when the sprite have a collision.
    .ctrlout:	resw 1	; Pointer tu event handler, when go out of scene
    .iavars	resw 1	; I.A. reserved variables.
    .x		resw 1
    .y		resw 1
    .nx		resw 1
    .ny		resw 1
    .h		resw 1
    .pxw		resw 1
    .bw	resw 1
    .next	resw 1	; Pointer to nexts prite in linked list
    .spritesheet	resw 1	; Pointer to SPRITESHEET structure
    .ssframe	resw 1	; Frame index in sprite sheet
    .gr0:	resw 1	; Pointer to graphic data
    .gr1:	resw 1	; Pointer to graphic data

  endstruc

  struc SPRITEPHYS	; Sprite with Physics

    .sprite:	resb SPRITE_size
    .vuelox:	resw 1
    .vxmax:	resw 1
    .deltay:	resw 1
    .saltoframes:	resb 1
    .parado:	resb 1

  endstruc

  struc ANIMSPRITEPHYS	; Animated Sprite with Physics

    .sprite:	resb SPRITEPHYS_size
    .direccion: resb 1
    .aframecount: resb 1

  endstruc

  ; Macros

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

  ; NYT: Nivel de tile vertical
  ; Calcula el nivel vertical en tiles al que pertenece una coordenada Y en pixeles
  %macro NYT 1
  %rep ilog2e( ALTOTILE )
  shr %1, 1
  %endrep
  %endmacro

  ; NXT: Nivel de tile horizontal
  ; Calcula el nivel horizontal en tiles al que pertenece una coordenada X en pixeles
  %macro NXT 1
  %rep ilog2e( ANCHOTILE )
  shr %1, 1
  %endrep
  %endmacro

  ; PYT: Pixel de tile vertical
  ; Calcula la coordenada Y en pixeles a la que corresponde un nivel Y de Tiles
  %macro PYT 1
  %rep ilog2e( ALTOTILE )
  shl %1, 1
  %endrep
  %endmacro

  ; PXT: Nivel de tile horizontal
  ; Calcula la coordenada X en pixeles a la que corresponde un nivel X de Tiles
  %macro PXT 1
  %rep ilog2e( ANCHOTILE )
  shl %1, 1
  %endrep
  %endmacro

  ; SPRITELOOP: Recorrer lista de Sprites
  %macro SPRITELOOP 0

    %push spriteloop
    mov ax, [firstsprite]
    test ax, ax
    jz %$end
    mov bp, ax
    %$begin:

  %endmacro

  %macro SPRITELOOPEND 0

    mov ax, [ds:bp + SPRITE.next]
    test ax, ax
    jz %$end
    mov bp, ax
    jmp %$begin
    %$end:

    %pop spriteloop

  %endmacro

  %macro SPRITESHEETLOOP 0

    %push spritesheetloop

    mov cx, [spritesheetscount]
    mov bp, spritesheetsstrucdata
    %$begin:
    push cx

  %endmacro


  %macro SPRITESHEETLOOPEND 0
    pop cx
    add bp, SPRITESHEET_size
    loop %$begin

    %pop spritesheetloop
  %endmacro

  org 100h
 
section .text 
 
start:

  ; 1 .- Guardar Rutina de interrupcion del teclado del sistema (BIOS)
  mov     al,9h
  mov     ah,35h
  int     21h
  mov [kb_int_old_off], bx
  mov [kb_int_old_seg], es

  call videomenu

  ; 2 .- Registrar nueva rutina de interrupción del teclado
  mov     al, 9h
  mov     ah, 25h
  mov     bx, cs
  mov     ds, bx
  mov     dx, kb_int_new
  int     21h



  ; Inicializar gráficos

  SPRITESHEETLOOP
  call inicializaspritegrafico
  SPRITESHEETLOOPEND


  SPRITELOOP
  call conectaspritegraficos
  SPRITELOOPEND

  ; x .- Draw map
  mov dx, map1
  call drawmap

  ; 4 .- Dibujar sprite en su posicion inicial

  SPRITELOOP
  call dibujasprite16
  SPRITELOOPEND

  ;jmp fin	; Temporal

  frame:

  mov al, [tecla_esc] ; ¿está presionada esta tecla?
  test al, al
  jnz fin

  SPRITELOOP
  xor al, al
  mov bx, [ds:bp + SPRITE.control]
  test bx, bx
  jz .fincontrol
  call bx
  .fincontrol:
  call [ds:bp + SPRITE.frame]
  ; call spritecollisions
  SPRITELOOPEND

  VSync

  SPRITELOOP
  call borraspritemov
  SPRITELOOPEND

  SPRITELOOP
  mov bx, bp
  mov ax, [bx + SPRITE.ny]
  mov [bx + SPRITE.y], ax
  mov ax, [bx + SPRITE.nx]
  mov [bx + SPRITE.x], ax
  SPRITELOOPEND

  SPRITELOOP
  call dibujasprite16
  SPRITELOOPEND

  ; repetir ciclo
  jmp frame

videomenu:


  ; 1.- Entrar en video modo 4
  mov  ah, SETVIDEOMODE   ; Establecer modo de video
  mov  al, 4      ; CGA Modo 4
  int  VIDEOBIOS   ; LLamar a la BIOS para servicios de video


  mov dh, 1
  mov dl, 10
  mov bx, video_menu_title
  mov cx, 1
  call writestring

  mov dh, 8
  mov dl, 1
  mov bx, video_menu_cga
  mov cx, 3
  call writestring

  mov dh, 10
  mov dl, 1
  mov bx, video_menu_composite
  mov cx, 3
  call writestring

  mov dh, 12
  mov dl, 1
  mov bx, video_menu_tandy
  mov cx, 3
  call writestring

  .leeteclado:
  mov ah, 0
  int 16h

  cmp al, '1'
  jne .nocga
  mov ah, SETVIDEOMODE
  mov al, 4
  int VIDEOBIOS

  ; Establecer paleta de colores
  mov dx, 03D9h
  mov al, 00011011b
  out dx, al

  mov byte [colorbackground], 0


  ret
  .nocga:

  cmp al, '2'
  jne .nocomposite
  mov ah, SETVIDEOMODE
  mov al, CGA6
  int VIDEOBIOS

  ; Entrar en modo de video compuesto
  mov dx, 03D8h
  mov al, 00011010b
  out dx, al

  ret
  .nocomposite:

  cmp al, '3'
  jne .notandy
  mov ah, SETVIDEOMODE
  mov al, 8
  int VIDEOBIOS

  mov bx, tilesgraphics
  mov cx, (endtilesgraphics - tilesgraphics)
  call conviertecomposite2tandy

  mov bx, spritesgraphics
  mov cx, (endspritesgraphics - spritesgraphics)
  call conviertecomposite2tandy

  mov bx, colorbackground
  mov cx, 1
  call conviertecomposite2tandy

  ret
  .notandy:

  jmp .leeteclado

  ; Asigna memoria
malloc:
  ; parametros:
  ; cx => Cantidad de memoria en bytes
  ; retorna:
  ; bx => direccion de memoria asignada

  mov bx, [allocend]
  mov ax, bx
  add ax, cx
  mov [allocend], ax
  ret


writestring:
  ; dh => row
  ; dl => col
  ; bx => zero-terminated string
  ; cl => Color

  ; 0.- Respaldar registros
  push si
  mov si, bx
  mov bl, cl
  xor bh, bh

  ; 1.- Establecer posición del cursor
  .loopchar:
  mov ah, 2
  int VIDEOBIOS

  ; 2.- Escribir caracteres

  lodsb
  test al, al
  jz .salir
  mov ah, 10d
  mov cx, 1
  int VIDEOBIOS
  inc dl
  jmp .loopchar

  .salir:
  pop si
  ret

drawmap:
  ; DX = Map data
  xor ax, ax	; AX = 0
  mov si, dx	; Load Map data on Source index

  .looprows:
  
  xor bx, bx	; BX = 0
  .loopcols:
  mov cx, ax
  lodsb
  xchg ax, cx
  call drawtilesimple
  inc bx
  cmp bx, MAPWIDTH
  jl .loopcols
  inc ax
  cmp ax, MAPHEIGHT
  jl .looprows
  ret
  


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

cambiapaleta:
  mov ah, [paleta]
  test ah, ah
  jz .sig
  mov bl, 0
  jmp .guarda
  .sig:
  mov bl, 1
  .guarda:
  mov [paleta], bl

  .llama_a_bios:
  mov ah, 0Bx	; Establecer paleta de colores
  mov bh, 1	; Paleta de cuatro colores
  mov bl, [paleta]
  int  VIDEOBIOS
  ret


sphysicsframe:
  ; Parametros:
  ; BP => sprite

  ; 1.- Leer el teclado


  .test_left:
  test al, LEFT
  jz .sig1

  .movizq:
  mov word [ds:bp + SPRITEPHYS.vuelox], -1
  jmp .testright

  .sig1:
  mov word [ds:bp + SPRITEPHYS.vuelox], 0
  ; jnl .testright

  .testright:
  test al, RIGHT
  jz .sig2

  .movder:
  mov word [ds:bp + SPRITEPHYS.vuelox], 1

  .sig2:



  .calcx:    ; 2.- calcular x

  mov bx, [ds:bp + SPRITE.x]
  mov dx, [ds:bp + SPRITEPHYS.vuelox]
  add bx, dx
  mov [ds:bp + SPRITE.nx], bx

  .saltar:
  ; ¿está presionada esta tecla?
  test al, UP
  jz .calcdy

  ; mov al, [ds:bp + SPRITEPHYS.parado] ; Tiene que estar parado para poder saltar
  ; test al, al
  ; jnz .sisaltar


  mov ah, [ds:bp + SPRITEPHYS.saltoframes] ; Si no está parado, pero aún tiene fuerza para saltar
  test ah, ah
  jz .calcdy

  .sisaltar:
  ; Ahora sí: Saltar porque estamos parados o tenemos fuerza para saltar y con la tecla saltar presionada
  mov bx, -FUERZASALTO
  mov [ds:bp + SPRITEPHYS.deltay], bx
  ; mov bx, 0
  dec ah
  mov [ds:bp + SPRITEPHYS.saltoframes], ah
  xor ah, ah
  mov [ds:bp + SPRITEPHYS.parado], ah


  .calcdy:  ; 2.- Calcular delta Y
  mov dx, [ds:bp + SPRITEPHYS.deltay]
  add dx, GRAVEDAD
  mov [ds:bp + SPRITEPHYS.deltay], dx

  .calcy:      ; 3.- calcular y
  
  mov ax, [ds:bp + SPRITE.y]
  mov bx, [ds:bp + SPRITEPHYS.deltay]
  add ax, bx
  mov [ds:bp + SPRITE.ny], ax
  ; mov [ds:bp + SPRITEPHYS.deltay], bx

  ; Fin de logica del jugador por frame
  ; call spritecollisions
  jmp spritecollisions
  ; ret

animphysspriteframe:

  xor dx, dx
  test al, LEFT
  jz .sig0
  mov [ds:bp + ANIMSPRITEPHYS.direccion], al
  inc dl
  jmp .sig00
  .sig0:
  test al, RIGHT
  jz .sig00
  mov byte [ds:bp + ANIMSPRITEPHYS.direccion], 0
  inc dl
  .sig00:

  xor bx, bx
  mov ah, [ds:bp + ANIMSPRITEPHYS.direccion]

  test ah, ah
  jnz .sig1
  add bh, 9
  .sig1:

  test al, UP
  jnz .saltar
  mov bl, [ds:bp + SPRITEPHYS.parado]
  test bl, bl
  jz .saltar

  .nosaltar:
  test dl, dl
  jz .dibujar
  mov dh, [ds:bp + ANIMSPRITEPHYS.aframecount]
  inc dh
  cmp dh, 8
  jl .sig2
  xor dh, dh
  .sig2:
  mov [ds:bp + ANIMSPRITEPHYS.aframecount], dh
  jmp .dibujar

  .saltar:
  mov dh, 8

  .dibujar:
  add bh, dh
  mov [ds:bp + SPRITE.ssframe], bh	; PRECAUCION: Usando solo 8 bits

  jmp sphysicsframe
  ; ret



kbcontrolfunc:
  xor al, al
  mov ah, [tecla_left]
  test ah, ah
  jz .sig1
  or al, LEFT
  .sig1:
  mov ah, [tecla_right]
  test ah, ah
  jz .sig2
  or al, RIGHT
  .sig2:
  mov ah, [tecla_up]
  test ah, ah
  jz .sig3
  or al, UP
  .sig3:
  mov ah, [tecla_down]
  test ah, ah
  jz .sig4
  or al, DOWN
  .sig4:

  ret

iabasiccontrol:
  mov al, [ds:bp + SPRITE.iavars]
ret

iabasiccoll:
  test al, al
  jz .sig2
  test ah, LEFT
  jz .sig1
  mov byte [ds:bp + SPRITE.iavars], RIGHT
  .sig1:
  test ah, RIGHT
  jz .sig2
  mov byte [ds:bp + SPRITE.iavars], LEFT
  .sig2:
  ; call spritephyscol
  jmp spritephyscol
  ; ret


spritephyscol:
  ; AH => Direccion
  ; AL => Tile
  test al, al
  jnz .nozero
  ret


  .nozero:
  mov ch, bh
  test ah, DOWN
  jnz .coldown
  test ah, UP
  jnz .colup
  test ah, RIGHT
  jnz .colright

  .colleft:
  
  PXT ch
  add ch, ANCHOTILE
  mov [ds:bp + SPRITE.nx], ch
  mov word [ds:bp + SPRITEPHYS.vuelox], 0
  
  .return:
  ret

  .coldown:
  PYT ch
  sub ch, [ds:bp + SPRITE.h]
  mov [ds:bp + SPRITE.ny], ch
  mov byte [ds:bp + SPRITEPHYS.parado], JUMPFRAMES
  mov byte [ds:bp + SPRITEPHYS.saltoframes], JUMPFRAMES
  mov word [ds:bp + SPRITEPHYS.deltay], 0

  ret

  .colup:
  PYT ch
  add ch, ALTOTILE
  mov [ds:bp + SPRITE.ny], ch
  ; mov byte [ds:bp + SPRITEPHYS.parado], 0
  mov byte [ds:bp + SPRITEPHYS.saltoframes], 0
  mov word [ds:bp + SPRITEPHYS.deltay], 0

  ret

  .colright:
  PXT ch
  sub ch, [ds:bp + SPRITE.pxw]
  mov [ds:bp + SPRITE.nx], ch
  mov word [ds:bp + SPRITEPHYS.vuelox], 0
  ; Activar lo siguiente en caso de querer rebote: (y desactivar linea de arriba)
  ; mov word dx, [ds:bp + SPRITEPHYS.vuelox]
  ; neg dx
  ; sar dx, 1
  ; mov word [ds:bp + SPRITEPHYS.vuelox], dx

  ret

spritephysout:
  ; AH => Direccion
  ; BX => Coordenada x o y, dependiendo de AH

  test ah, DOWN
  jnz .coldown
  test ah, UP
  jnz .colup
  test ah, RIGHT
  jnz .colright

  .colleft:
  mov word [ds:bp + SPRITE.nx], 0
  mov word [ds:bp + SPRITEPHYS.vuelox], 0
  ret

  .colright:
  mov ax, WIDTHPX
  sub ax, [ds:bp + SPRITE.pxw]
  mov [ds:bp + SPRITE.nx], ax
  mov word [ds:bp + SPRITEPHYS.vuelox], 0
  ret

  .colup:
  mov word [ds:bp + SPRITE.ny], 0
  mov word [ds:bp + SPRITEPHYS.deltay], 0
  ret

  .coldown:
  mov dx, HEIGHTPX
  sub dx, [ds:bp + SPRITE.h]
  mov [ds:bp + SPRITE.ny], dx
  mov word [ds:bp + SPRITEPHYS.deltay], 0
  mov word [ds:bp + SPRITEPHYS.saltoframes], JUMPFRAMES


  ret


spritecollisions:
  ; parametros:
  ; DS:BP => Sprite
  ; Mapa? TODO: obtener como parámetro

  ; 0 .- Revisar que no se salga

  ; 0.1 .- horizontal

  mov bx, [ds:bp + SPRITE.nx]
  mov cx, bx
  add cx, [ds:bp + SPRITE.pxw]
  cmp cx, WIDTHPX
  jng .outxl

  mov ah, RIGHT
  call [ds:bp + SPRITE.ctrlout]
  jmp .noutx

  .outxl:
  cmp bx, 0
  jnl .noutx

  mov ah, LEFT
  call [ds:bp + SPRITE.ctrlout]

  .noutx:

  ; 0.2 .- Vertical


  ; 1.1.- revisar que no se salga
  mov bx, [ds:bp + SPRITE.ny]
  mov dx, HEIGHTPX
  sub dx, [ds:bp + SPRITE.h]

  cmp bx, dx
  jng .outyu

  mov ah, DOWN
  call [ds:bp + SPRITE.ctrlout]

  jmp .nouty

  .outyu:
  cmp bx, 0
  jnl .nouty

  mov ah, UP
  call [ds:bp + SPRITE.ctrlout]

  .nouty:


  mov bx, map1
  ; mov si, bx
  mov di, bx

  .vertical:
  mov bh, [ds:bp + SPRITE.y]
  mov bl, [ds:bp + SPRITE.ny]
  cmp bh, bl
  je .horizontal	; Si y == ny, es que no hay movimiento vertical
  ja .movarriba
  .movabajo:
  mov al, [ds:bp + SPRITE.h]
  dec al
  add bh, al
  add bl, al
  NYT bh
  NYT bl
  cmp bh, bl
  jge .horizontal
  inc bh
  .loopnivelabajo:
  mov al, bh	; multiplicar nivel del tile Y
  mov cl, MAPWIDTH
  mul cl
  xor dx, dx
  mov dl, [ds:bp + SPRITE.nx]
  NXT dl
  mov cx, di
  mov si, cx
  add ax, dx
  add si, ax
  mov dh, [ds:bp + SPRITE.nx]
  add dh, [ds:bp + SPRITE.pxw]
  dec dh
  NXT dh
  mov ah, DOWN
  .looptileabajo:
  lodsb
  call [ds:bp + SPRITE.ctrlcoll]
  inc dl
  cmp dh, dl
  jge .looptileabajo
  inc bh	; siguiente renglon/nivel
  cmp bh, bl
  jle .loopnivelabajo

  jmp .horizontal


  .movarriba:
  mov bh, [ds:bp + SPRITE.y]	; Estas dos lineas están de mas?
  mov bl, [ds:bp + SPRITE.ny]
  NYT bh
  NYT bl
  cmp bh, bl
  jle .horizontal
  dec bh
  .loopnivelarriba:
  mov al, bh	; Multiplicar nivel de tile Y
  mov cl, MAPWIDTH
  mul cl
  xor dx, dx
  mov dl, [ds:bp + SPRITE.nx]
  NXT dl
  mov cx, di
  mov si, cx
  add ax, dx
  add si, ax
  mov dh, [ds:bp + SPRITE.nx]
  add dh, [ds:bp + SPRITE.pxw]
  dec dh
  NXT dh
  mov ah, UP
  .looptilearriba:
  lodsb
  call [ds:bp + SPRITE.ctrlcoll]
  inc dl
  cmp dh, dl
  jge .looptilearriba
  dec bh	; renglon / nivel arriba
  cmp bh, bl
  jge .loopnivelarriba
  ; jmp .horizontal


  .horizontal:
  mov bh, [ds:bp + SPRITE.x]
  mov bl, [ds:bp + SPRITE.nx]
  cmp bh, bl
  je .fin
  ja .movizquierda
  .movderecha:
  mov ch, [ds:bp + SPRITE.pxw]
  dec ch
  add bh, ch
  add bl, ch
  NXT bh
  NXT bl
  cmp bh, bl
  jge .fin
  inc bh
  .loopnivelderecha:
  ; Calcular SI
  mov al, [ds:bp + SPRITE.ny]
  NYT al
  mov ah, MAPWIDTH
  mul ah
  xor dx, dx
  mov dl, bh
  add ax, dx
  mov cx, di
  mov si, cx
  add si, ax
  mov dl, [ds:bp + SPRITE.ny]
  mov dh, dl
  add dh, [ds:bp + SPRITE.h]
  dec dh
  NYT dl
  NYT dh
  mov ah, RIGHT
  .looptilederecha:
  lodsb
  call [ds:bp + SPRITE.ctrlcoll]
  add si, MAPWIDTH - 1
  inc dl
  cmp dh, dl
  jge .looptilederecha
  inc bh
  cmp bh, bl
  jle .loopnivelderecha
  jmp .fin


  .movizquierda:
  NXT bh
  NXT bl
  cmp bh, bl
  jle .fin
  dec bh
  .loopnivelizquierda:
  ; Calcular SI
  mov al, [ds:bp + SPRITE.ny]
  NYT al
  mov ah, MAPWIDTH
  mul ah
  xor dx, dx
  mov dl, bh
  add ax, dx
  mov cx, di
  mov si, cx
  add si, ax
  mov dl, [ds:bp + SPRITE.ny]
  mov dh, dl
  add dh, [ds:bp + SPRITE.h]
  dec dh
  NYT dl
  NYT dh
  mov ah, LEFT
  .looptileizquierda:
  lodsb
  call [ds:bp + SPRITE.ctrlcoll]
  add si, MAPWIDTH - 1
  inc dl
  cmp dh, dl
  jge .looptileizquierda
  dec bh
  cmp bh, bl
  jge .loopnivelizquierda
  ; jmp .fin


  .fin:
  ret


fin:
  ; 1 .- Reestablecer rutina original de manejo de teclado
  mov     dx,[kb_int_old_off]
  mov     ax,[kb_int_old_seg]
  mov     ds,ax
  mov     al,9h
  mov     ah,25h
  int     21h

  ; 2 .- Restablecer video modo de texto a color


  mov  ah, SETVIDEOMODE   ; Establecer modo de video
  mov  al, 3      ; CGA Modo texto a color, 80 x 25
  int  VIDEOBIOS   ; LLamar a la BIOS para servicios de video


  ; 3 .- Salir al sistema
  int 20h



dibujasprite16:
  ; Parametros:
  ; BP: sprite

  mov bx, [ds:bp + SPRITE.x]

  ; -1.- Revisar si pixeles están alineados con bytes
  test bx, 0000001b
  jnz dibujasprite16noalineado
  shr bx, 1

  ; 0.- Cargar direccion de mapa de bits

  mov ah, [ds:bp + SPRITE.bw]

  mov al, [ds:bp + SPRITE.ssframe]
  mul ah
  mov ah, [ds:bp + SPRITE.h]
  mul ah

  add ax, [ds:bp + SPRITE.gr0]
  mov si, ax

  ; 1.- Seleccionar banco de memoria

  mov cx, MEMCGAEVEN
  mov es, cx
  ; mov cx, ax  ; Copiar / respaldar coordenada Y
  mov ax, [ds:bp + SPRITE.y]
  mov cx, ax
  shr ax, 1 ; Descartar el bit de selección de banco

  ; 2.- Multiplicar
  mov dl, BYTESPERSCAN
  mul dl    ; multiplicar por ancho de pantalla en bytes
  add ax, bx  ; Desplazamiento del byte que vamos a manipular
  mov di, ax

  ; 3.- En caso de que coordenada Y sea impar, comenzar a dibujar sprite desde
  ; la segunda fila de pixeles del mapa de bits en coordenada par de pantalla.
  ; mov cx, [ds:bp + SPRITE.y]
  test cx, 00000001b
  jz .espar
  add si, [ds:bp + SPRITE.bw]
  add di, BYTESPERSCAN
  .espar: pushf

  mov cx, [ds:bp + SPRITE.h]  ; 4 .- Primero dibujamos mitad de renglones (en renglones par de patalla)
  shr cx, 1

  .looprenglon:

  mov dx, cx	; respaldar conteo de renglones
  mov cx, [ds:bp + SPRITE.bw]	; Bytes a copiar por renglon
  rep movsb
  mov cx, dx	; restaurar conteo de renglones

  add di, BYTESPERSCAN; Agregar suficientes bytes para que sea siguiente renglon
  sub di, [ds:bp + SPRITE.bw] ; TODO: ¿Optimizar para acceder solo una vez a ancho de sprite?
  add si, [ds:bp + SPRITE.bw] ; Saltar renglones de ssprite.mapa de bits
  loop .looprenglon

  ; 5 .- Después dibujamos otra mitad de renglones de sprite, ahora en renglones impar de pantalla

  mov cx, MEMCGAODD ; Dibujar en renglones impar de pantalla CGA 4 Col
  mov es, cx

  mov al, [ds:bp + SPRITE.h]
  mov dl, al
  shr al,1
  mov ah, BYTESPERSCAN
  mul ah
  sub di, ax	; Retroceder hasta posicion inicial en pantalla ? (pero ahora en renglon impar)
  mov al, dl
  dec al
  mov ah, [ds:bp + SPRITE.bw]
  mul ah
  sub si, ax	; retrocedemos hasta posicion inicial de sprite + un renglon

  popf ; ¿Necesario?
  jz .espar2
  sub si, [ds:bp + SPRITE.bw]
  sub si, [ds:bp + SPRITE.bw]
  sub di, BYTESPERSCAN
  .espar2:

  mov cx, [ds:bp + SPRITE.h]
  shr cx, 1

  .looprenglon2:

  mov dx, cx	; respaldar conteo de renglones
  mov cx, [ds:bp + SPRITE.bw]	; Bytes a copiar por renglon
  rep movsb
  mov cx, dx	; restaurar conteo de renglones

  add di, BYTESPERSCAN ; Agregar suficientes bytes para que sea siguiente renglon
  sub di, [ds:bp + SPRITE.bw]
  add si, [ds:bp + SPRITE.bw] ; Saltar renglones de ssprite.mapa de bits
  loop .looprenglon2

  ret

dibujasprite16noalineado:

  ; 0.- Cargar direccion de mapa de bits

  mov ah, [ds:bp + SPRITE.bw]

  mov al, [ds:bp + SPRITE.ssframe]
  mul ah
  mov ah, [ds:bp + SPRITE.h]
  mul ah

  add ax, [ds:bp + SPRITE.gr1]
  mov si, ax


  ; 1.- Seleccionar banco de memoria

  mov cx, MEMCGAEVEN
  mov es, cx

  mov ax, [ds:bp + SPRITE.y]
  mov cx, ax  ; Copiar / respaldar coordenada Y
  shr ax, 1 ; Descartar el bit de selección de banco

  ; 2.- Multiplicar
  mov dl, BYTESPERSCAN
  mul dl    ; multiplicar por ancho de pantalla en bytes
  mov bx, [ds:bp + SPRITE.x]
  mov dx, bx  ; Copiar coordenada X
  shr dx, 1   ; Descartar ultimo bit
  add ax, dx  ; Desplazamiento del byte que vamos a manipular
  mov di, ax
  and bx, 00000001b	; Usar solo ultimo bit para posicion sub-byte

  ; 3.- En caso de que coordenada Y sea impar, comenzar a dibujar sprite desde
  ; la segunda fila de pixeles del mapa de bits en coordenada par de pantalla.
  test cx, 00000001b
  jz .espar
  add si, [ds:bp + SPRITE.bw]
  add di, BYTESPERSCAN
  .espar pushf

  mov cx, [ds:bp + SPRITE.h]  ; 4 .- Primero dibujamos mitad de renglones (en renglones par de patalla)
  shr cx, 1


  .looprenglon:

  mov dx, cx ; guardar contador de renglones

  ; primer pixel del renglón
  ; Conservar el pixel de la izquierda, que pertenece al fondo?

  mov ah, [es:di]
  and ah, 11110000b
  lodsb
  and al, 00001111b
  or al, ah
  stosb

  mov cx, [ds:bp + SPRITE.bw]	; numero de bytes a copiar
  dec cx

  ; ultimo pixel del renglón
  ; Conservar el pixel de la derecha, que pertenece al fondo?

  rep movsb
  mov ah, [es:di]
  and ah, 00001111b
  lodsb
  and al, 11110000b
  or al, ah
  stosb


  add di, BYTESPERSCAN ; Agregar suficientes bytes para que sea siguiente renglon
  sub di, [ds:bp + SPRITE.bw]
  dec di
  add si, [ds:bp + SPRITE.bw]	; Saltar renglones de sprite.mapa de bits
  dec si

  mov cx, dx  ; contador de renglones
  loop .looprenglon

  ;popf	; Salir por mientras
  ;ret
  ; 5 .- Después dibujamos otra mitad de renglones de sprite, ahora en renglones impar de pantalla

  mov cx, MEMCGAODD ; Dibujar en renglones impar de pantalla CGA 4 Col
  mov es, cx

  mov al, [ds:bp + SPRITE.h]
  mov dl, al
  shr al,1
  mov ah, BYTESPERSCAN
  mul ah
  sub di, ax	; Retroceder hasta posicion inicial en pantalla ? (pero ahora en renglon impar)
  mov al, dl
  dec al
  mov ah, [ds:bp + SPRITE.bw]
  mul ah
  sub si, ax	; retrocedemos hasta posicion inicial de sprite + un renglon


  popf ; ¿Necesario?
  jz .espar2
  sub si, [ds:bp + SPRITE.bw]
  sub si, [ds:bp + SPRITE.bw]
  sub di, BYTESPERSCAN
  .espar2:

  mov cx, [ds:bp + SPRITE.h]
  shr cx, 1

  .looprenglon2:

  mov dx, cx ; guardar contador de renglones
  
  ; primer pixel del renglón
  ; Conservar el pixel de la izquierda, que pertenece al fondo?

  mov ah, [es:di]
  and ah, 11110000b
  lodsb
  and al, 00001111b
  or al, ah
  stosb

  mov cx, [ds:bp + SPRITE.bw]	; numero de bytes a copiar
  dec cx
  rep movsb

  ; ultimp pixel del renglón
  ; Conservar el pixel de la derecha, que pertenece al fondo?

  rep movsb ; ???
  mov ah, [es:di]
  and ah, 00001111b
  lodsb
  and al, 11110000b
  or al, ah
  stosb


  add di, BYTESPERSCAN	; Agregar suficientes bytes para que sea siguiente renglon
  sub di, [ds:bp + SPRITE.bw]
  dec di
  add si, [ds:bp + SPRITE.bw] ; Saltar renglones de ssprite.mapa de bits
  dec si
  mov cx, dx  ; contador de renglones
  loop .looprenglon2


  ; Fin. Retornar
  ret

borraspritemov:
  ; Optimized routine for erasing only the pixels that needs to be erased
  ; DS:BP => Sprite

  ; 1.- Check if moved vertically

  .checkvertical:
  mov ax, [ds:bp + SPRITE.y]
  mov bx, [ds:bp + SPRITE.ny]
  cmp ax, bx
  je .checkhorizontal	; Si son iguales es que no hay mov vertical
  jg .bkvertical	; Si y es mayor que ny, vamos hacia abajo
			; Si y es nemor que ny, vamos hacia arriba
			; ax => c.y = s.y
  sub bx, ax		; bx => c.h = s.ny - s.y
  jmp .clearvertical

  .bkvertical:
  xchg ax, bx		; ax => s.ny, bx => s.y
  sub bx, ax		; bx => s.ny - s.y	(numero negativo)
  ; neg bx		; bx => c.h = s.y - s.ny (numero positivo)
  add ax, [ds:bp + SPRITE.h]	; ax => c.y = s.ny + s.h

  .clearvertical:
  ; ax => c.y
  ; bx => c.h

  ; mov ax, 3
  ; mov bx, 4

  mov cx, MEMCGAEVEN
  mov es, cx
  mov cx, ax	; respaldar coordenada y
  shr ax, 1	; Descartar bit de seleccion de banco
  ; multiplicar
  mov dx, BYTESPERSCAN
  mul dl	; multiplicar por ancho de pantalla en bytes
  mov dx, [ds:bp + SPRITE.x]
  shr dx, 1	; Descartar ultimo bit (posicion de pixel dentro del byte)
  add ax, dx	; Direccion en memoria donde comenzamos a borrar
  mov di, ax

  ; En caso de que coordenada Y sea impar, comenzar a borrar desde
  ; la segunda fila de pixeles del mapa de bits en coordenada par de pantalla.
  mov dx, bx
  shr dx, 1
  mov ax, bx
  and ax, 00000001b
  test cx, 00000001b
  pushf
  jz .espar
  add di, BYTESPERSCAN
  jmp .sig1
  .espar:
  add dx, ax
  .sig1:
  .initlooprow:
  mov cx, dx
  mov al, [colorbackground]
  mov ah, bl	; respaldar ¿altura de Sprite?

  mov bx, [ds:bp + SPRITE.x]
  and bx, 00000001b
  add bx, [ds:bp + SPRITE.bw]

  test cx, cx
  jz .finlooprow
  .looprenglon:
  mov dx, cx
  mov cx, bx
  rep stosb
  mov cx, dx
  add di, BYTESPERSCAN
  sub di, bx
  loop .looprenglon
  .finlooprow:
  xor bh, bh
  mov bl, ah

  mov cx, es
  cmp cx, MEMCGAODD
  je .checkhorizontal

  mov cx, MEMCGAODD
  mov es, cx
  mov ax, bx
  shr ax, 1
  mov dl, BYTESPERSCAN
  mul dl
  sub di, ax ; TODO: Ver como optimizar esto, junto con el siguiente 'jz .espar2'
  ; sub di, BYTESPERSCAN * ( ALTOSPRITE / 2 )
  mov dx, bx
  shr dx, 1
  mov ax, bx
  and ax, 00000001b
  popf
  jz .espar2
  add dx, ax
  sub di, BYTESPERSCAN
  jmp .sig2
  .espar2:
  test ax, 00000001b
  jz .sig2
  sub di, BYTESPERSCAN
  .sig2:
  test dx, dx
  jnz .initlooprow


  .checkhorizontal:
  mov dh, [ds:bp + SPRITE.x]
  mov dl, [ds:bp + SPRITE.nx]
  cmp dh, dl
  je .salir
  ja .mizq
  .mder:	; dh => c.x = s.x
  sub dl, dh	; dl => c.w = s.nx - s.x
  jmp .sig3
  .mizq:
  xchg dh, dl	; dl => s.x, dh = s.nx
  sub dl, dh	; dl => c.w = s.x - s.nx
  add dh, [ds:bp + SPRITE.pxw]	; dh => c.x = s.nx + s.w
  .sig3:
  ; dh => c.x
  ; dl => c.w

  ; Calcular movimiento vertical para borrado de seccion horizontal
  mov bh, [ds:bp + SPRITE.h]
  mov al, [ds:bp + SPRITE.y]
  mov bl, [ds:bp + SPRITE.ny]
  cmp al, bl
  jl .mdown
  xchg al, bl	; al => s.ny, bl => s.y
  .mdown:
  mov cl, bl
  sub bl, al
  sub bh, bl	; bh => c.h, al => c.y
  je .salir	; ?? Salir en caso de que sea menor o igual a cero ?
  mov al, cl
  .clearhorizontal:
  ; dh => c.x
  ; dl => c.w
  ; bh => c.h
  ; al => c.y
  
  mov cx, MEMCGAEVEN
  mov es, cx
  mov bl, al	; bl => c.y
  shr al, 1	; descartar bit de seleccion de banco
  mov ah, BYTESPERSCAN	; multiplicar por ancho de pantalla en bytes
  mul ah	; ax => desplazamiento en bytes del renglon
  xor cx, cx
  mov cl, dh	; cx => c.x
  shr cx, 1	; descartar utlimo bit	(posicion de pixel intra-byte)
  add ax, cx	; ax => Direccion de memoria donde empezamos a borrar
  mov di, ax	; Destination index = posicion inicial a borrar
		; ax queda libre para usar en otras cosas

  xor ch, ch
  mov cl, bh	; cx => c.h
  shr cx, 1	; dividir numero de renglones entre dos (para escaneo par)
  test bl, 00000001b	; ver si coordenada y es par
  jz .espar3
  add di, BYTESPERSCAN	; Comenzar en un renglón más abajo en caso de coordenada impar
  jmp .sig4
  .espar3:
  ; mov al, bh	; al => c.h
  ; and al, 00000001b
  ; xor ah, ah
  ; and cx, ax	; incrementar numero de renglones en escaneo par en caso de que
  		; renglones totales sea impar y coordenada y par
  test bh, 00000001b
  jz .sig4
  inc cx
  .sig4:
  .initlooprowh:
  push bx	; ¿Aun es necesario respaldar estas variables?
  ; push dx
  mov al, [colorbackground]
  mov ah, dl	; ah => c.w
  shr ah, 1	; dividir entre dos pixeles por byte
  mov bl, dl
  or bl, dh
  and bl, 00000001b	; agregar un byte si numero de pixeles es impar
  add ah, bl	; ah => numero de bytes a escribir horizontalmente
  test cx, cx
  jz .finlooprowh
  .looprowh:
  mov bx, cx	; respaldar conteo de renglones
  xor ch, ch
  mov cl, ah
  rep stosb
  mov cx, bx	; restaurar conteo de renglones
  xor bx, bx
  mov bl, ah
  sub bx, BYTESPERSCAN
  sub di, bx
  loop .looprowh
  .finlooprowh:
  pop bx

  mov cx, es
  cmp cx, MEMCGAODD
  je .salir

  mov cx, MEMCGAODD
  mov es,cx

  ; xor ax, ax
  mov al, bl	; al => c.y
  shr al, 1
  mov ah, BYTESPERSCAN
  mul ah	; ax => desplazamiento en bytes del renglon
  xor cx, cx
  mov cl, dh	; cx => c.x
  shr cx, 1	; descartar utlimo bit (posicion de pixel intra-byte)
  add ax, cx
  mov di, ax

  xor cx, cx
  mov cl, bh	; cx => c.h
  shr cx, 1	; dividir numero de renglones entre dos (para escaneo impar)
  test bl, 00000001b	; ver si coordenada c.y es impar
  jz .espar4
  test bh, 00000001b	; y además altura c.h es impar
  jz .espar4
  inc cx		; si ambos sin impares: incrementar numero de renglones
  			; a dibujar en lineas de escaneo impar de pantalla
  .espar4:
  jmp .initlooprowh
  test cx, cx
  ;jz .salir		; salir en caso de que conteo de renglones sea cero
  jnz .initlooprowh



  .salir:
  ret

borrasprite16:

  ; Parametros:
  ; BP => sprite

  ; 1.- Seleccionar banco de memoria

  mov cx, MEMCGAEVEN
  mov es, cx
  mov ax, [ds:bp + SPRITE.y]
  mov cx, ax  ; Copiar / respaldar coordenada Y
  shr ax, 1 ; Descartar el bit de selección de banco

  ; Multiplicar
  mov dl, BYTESPERSCAN
  mul dl    ; multiplicar por ancho de pantalla en bytes

  mov dx, [ds:bp + SPRITE.bw]	; guardar ancho de sprite en pixeles

  mov bx, [ds:bp + SPRITE.x]
  shr bx, 1

  jnc .sig1	; Incrementar numero de bytes a borrar si la alineacion x es non
  inc dx
  .sig1:

  add ax, bx  ; Desplazamiento del byte que vamos a manipular
  mov di, ax

  ; En caso de que coordenada Y sea impar, comenzar a borrar sprite desde
  ; la segunda fila de pixeles del mapa de bits en coordenada par de pantalla.
  test cx, 00000001b
  jz .espar
  add di, BYTESPERSCAN
  .espar pushf

  ; Primero borramos mitad de renglones (en renglones par de patalla)
  mov cx, [ds:bp + SPRITE.h]
  shr cx, 1

  ; xor ax, ax  ; Registro AX en ceros
  ; mov ax, 1010101010101010b <= debug
  mov ax, [colorbackground]

  .looprenglon:
  mov bx, cx
  mov cx, dx
  rep stosb
  mov cx, bx

  add di, BYTESPERSCAN		; Agregar suficientes bytes para que sea siguiente renglon
  sub di, dx
  loop .looprenglon

  ; Después dibujamos otra mitad de renglones de sprite, ahora en renglones impar de pantalla

  mov cx, MEMCGAODD ; Dibujar en renglones impar de pantalla CGA 4 Col
  mov es, cx

  mov bx, ax
  mov al, [ds:bp + SPRITE.h]
  shr al,1
  mov ah, BYTESPERSCAN
  mul ah
  sub di, ax	; Retroceder hasta posicion inicial en pantalla ? (pero ahora en renglon impar)
  mov ax, bx

  popf ; ¿Necesario?
  jz .espar2
  sub di, BYTESPERSCAN
  .espar2:

  mov cx, [ds:bp + SPRITE.h]
  shr cx, 1

  .looprenglon2:
  mov bx, cx
  mov cx, dx
  rep stosb
  mov cx, bx

  add di, BYTESPERSCAN		; Agregar suficientes bytes para que sea siguiente renglon
  sub di, dx
  loop .looprenglon2

  ret


drawtilesimple:
  ; AX = Y Coordinate of tile
  ; BX = X Coordinate of tile
  ; CX = Tile Code
  push si
  push ax	; Respaldar AX y BX
  push bx

  ; 1 .- Seleccionar banco de memoria
  mov dx, MEMCGAEVEN
  mov es, dx
  mov dx, cs
  mov ds, dx

  ; 2 .- Multiplicar para calcular desplazamiento
  mov dl, BYTESPERSCAN
  mul dl	; Multiply by screen width in bytes
  mov dx, cx
  mov cx, ( ilog2e( ALTOTILE ) - 1 )
  shl ax, cl

  ; 3 .- Multiplicar X por ancho de TILE
  mov cx, ilog2e(ANCHOTILE / PXB)
  shl bx, cl

  ; 4 .- Sumar
  add ax, bx
  mov di, ax	; Destination Index


  lea si, [tilesgraphics]
  ; mov si, bx
  mov al, dl
  mov ah, 64
  mul ah
  add si, ax
  ; mov si, bx

  .draw:
  mov cx, ( ALTOTILE / 2 )  ; Primero dibujamos mitad de renglones (en renglones par de patalla)

  .looprenglon:
  mov dx, cx	; respaldar cx
  mov cx, ( ANCHOTILE / PXB )
  rep movsb
  mov cx, dx	; Reestablecer cx
  add di, BYTESPERSCAN - ( ANCHOTILE / PXB )
  add si, ( ANCHOTILE / PXB )
  loop .looprenglon

  mov cx, es
  cmp cx, MEMCGAODD
  je .salir

  mov cx, MEMCGAODD
  mov es, cx
  sub di, BYTESPERSCAN * ( ALTOTILE / 2 )
  sub si, ( ANCHOTILE / PXB ) * ( ALTOTILE - 1 )
  jmp .draw

  .salir:
  pop bx	; Restaurar bx y ax
  pop ax
  pop si
  ret

conviertecomposite2tandy:
  ; bx => graficos a convertir
  ; cx => cantidad de bytes a convertir
  push si
  push di

  mov ax, cs	; Esto sólo funciona en ejecutables ".com" Cambiar en caso de ".exe"
  mov ds, ax
  mov es, ax

  mov si, bx
  mov di, bx

  mov bx, comp2tdy_table

  .loopbyte:
  lodsb
  mov dx, cx
  mov ah, al
  and al, 00001111b
  xlatb
  xchg ah, al
  mov cl, 4
  shr al, cl
  xlatb
  mov cl, 4
  shl al, cl
  or al, ah
  stosb
  mov cx, dx
  loop .loopbyte

  pop di
  pop si
  ret

inicializaspritegrafico:
  ; Parametros:
  ; BP => spritegrafico

  mov bx, ds
  mov es, bx

  mov si, [ds:bp + SPRITESHEET.gr0]

  mov ah, [ds:bp + SPRITESHEET.w]

  %rep ilog2e( PXB )
  shr ah, 1
  %endrep

  mov al, [ds:bp + SPRITESHEET.framescount]
  mul ah
  mov ah, [ds:bp + SPRITESHEET.h]	; Precaución: Estamos asumiendo que
  mul ah		; resultado de multiplicacion cabe en un solo byte (AL)
  inc ax
  mov dx, ax
  mov cx, ax
  call malloc		; Asignar memoria
  mov di, bx		; Memoria asignada en Destination Index
  mov [ds:bp + SPRITESHEET.gr1], bx		; Memoria asignada en estructura Sprite

  .px0:		; guardar el primer pixel con desplazamiento de bits

  mov cx, 4 	; guardar bits a desplazar en el contador
  xor ax, ax	; borrar ax
  lodsb		; cargar byte en al
  shr ax, cl	; desplazar esa cantidad de bits
  stosb		; Escribir byte

  mov cx, dx
  dec cx
  dec cx

  .loopbyte:
  mov bx, cx
  dec si
  lodsw
  xchg ah, al
  mov cx, 4
  shr ax, cl    ; desplazar esa cantidad de bits
  stosb		; Escribir byte (?)
  mov cx, bx
  loop .loopbyte

  xor ax, ax
  mov ah, [ds:si - 1]
  mov cx, 4
  shr ax, cl
  stosb

  ret


conectaspritegraficos:
  ; Parametros:
  ; BP => sprite

  mov bx, [ds:bp + SPRITE.spritesheet]

  mov ax, [bx + SPRITESHEET.gr0]
  mov [ds:bp + SPRITE.gr0], ax

  mov ax, [bx + SPRITESHEET.gr1]
  mov [ds:bp + SPRITE.gr1], ax

  mov ax, [bx + SPRITESHEET.h]
  mov [ds:bp + SPRITE.h], ax

  mov ax, [bx + SPRITESHEET.w]
  mov [ds:bp + SPRITE.pxw], ax

  %rep ilog2e( PXB )
  shr ax, 1
  %endrep

  mov [ds:bp + SPRITE.bw], ax

  ret

section .data
  ; program data

  ; Trabla de equivalencia entre paletas de colores Composite => Tandy
  comp2tdy_table:

  db 0, 2, 1, 3, 4, 7, 5, 11, 6, 10, 8, 10, 12, 14, 13, 15

  video_menu_title: db 'Select video mode', 0

  video_menu_cga: db '1 CGA RGBI Monitor', 0

  video_menu_composite: db '2 CGA/TANDY Composite Monitor or TV', 0

  video_menu_tandy: db '3 TANDY RGBI Monitor', 0


  kb_int_old_off: dw  0
  kb_int_old_seg: dw  0

  ; Estado de las teclas:
  tecla_esc: db 0
  tecla_up: db 0
  tecla_down: db 0
  tecla_left: db 0
  tecla_right: db 0

  ; Variables del programa:

  paleta:
  db 1

  spritesheetscount:	dw 3

  spritesheetsstrucdata:

  spritesheetmono1:
    istruc SPRITESHEET
    at SPRITESHEET.framescount, dw 18
    at SPRITESHEET.h, dw 32
    at SPRITESHEET.w, dw 8
    at SPRITESHEET.gr0, dw spritedatamonigote
    at SPRITESHEET.4colgr, dw spritedatamonigote
    at SPRITESHEET.16colgr, dw spritedatamonigote

  spritesheetgrande:
    istruc SPRITESHEET
    at SPRITESHEET.framescount, dw 1
    at SPRITESHEET.h, dw 32
    at SPRITESHEET.w, dw 16
    at SPRITESHEET.gr0, dw spritedatamonogrande
    at SPRITESHEET.4colgr, dw spritedatamonogrande
    at SPRITESHEET.16colgr, dw spritedatamonogrande

  spritesheetmonochico:
    istruc SPRITESHEET
    at SPRITESHEET.framescount, dw 1
    at SPRITESHEET.h, dw 16
    at SPRITESHEET.w, dw 8
    at SPRITESHEET.gr0, dw spritedatamonochico
    at SPRITESHEET.4colgr, dw spritedatamonochico
    at SPRITESHEET.16colgr, dw spritedatamonochico

  spritesheetmona:
    istruc SPRITESHEET
    at SPRITESHEET.framescount, dw 1
    at SPRITESHEET.h, dw 32
    at SPRITESHEET.w, dw 8
    at SPRITESHEET.gr0, dw spritedatamona
    at SPRITESHEET.4colgr, dw spritedatamona
    at SPRITESHEET.16colgr, dw spritedatamona

  playersprite:
    istruc ANIMSPRITEPHYS
    at SPRITE.frame, dw animphysspriteframe
    at SPRITE.control, dw kbcontrolfunc
    at SPRITE.ctrlcoll, dw spritephyscol
    at SPRITE.ctrlout, dw spritephysout
    at SPRITE.iavars, dw 0
    at SPRITE.x, dw 120d
    at SPRITE.y, dw 16d
    at SPRITE.nx, dw 0
    at SPRITE.ny, dw 0
    ; at SPRITE.h, dw 32
    ; at SPRITE.pxw, dw 8
    at SPRITE.next, dw playersprite2
    at SPRITE.spritesheet, dw spritesheetmono1
    at SPRITE.ssframe, dw 0
    at SPRITEPHYS.vuelox, dw 0
    at SPRITEPHYS.deltay, dw 0
    at SPRITEPHYS.saltoframes, db 0
    at SPRITEPHYS.parado, db 0
    at ANIMSPRITEPHYS.direccion, db 0
    at ANIMSPRITEPHYS.aframecount, db 0

  playersprite2:
    istruc SPRITEPHYS
    at SPRITE.frame, dw sphysicsframe
    at SPRITE.control, dw iabasiccontrol
    at SPRITE.ctrlcoll, dw iabasiccoll
    at SPRITE.ctrlout, dw spritephysout
    at SPRITE.iavars, dw LEFT
    at SPRITE.x, dw 40d
    at SPRITE.y, dw 80d
    at SPRITE.nx, dw 0
    at SPRITE.ny, dw 0
    ; at SPRITE.h, dw 32
    ; at SPRITE.pxw, dw 16
    at SPRITE.next, dw 0
    at SPRITE.spritesheet, dw spritesheetgrande
    at SPRITEPHYS.vuelox, dw 0
    at SPRITEPHYS.deltay, dw 0
    at SPRITEPHYS.saltoframes, db 0
    at SPRITEPHYS.parado, db 0

  firstsprite:
  dw playersprite



map1:


  db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 3, 4, 5, 0, 0, 0, 0, 0
  db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6, 0, 0
  db 2, 3, 4, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 6, 0, 0, 0
  db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  db 0, 0, 0, 0, 0, 0, 0, 6, 6, 0, 0, 6, 0, 0, 0, 0, 0, 0, 2, 3
  db 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 6, 0, 0, 0, 0, 0, 0, 0
  db 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6, 1, 2, 0, 0, 0, 0, 0, 0
  db 1, 4, 5, 3, 1, 2, 4, 5, 5, 4, 4, 1, 1, 2, 3, 4, 5, 5, 4, 4


colorbackground: db 77h


align   8,db 0

spritesgraphics:
spritedatamonigote:

incbin	"img/jugador-spritesheet-izq.bin",0,1152
incbin	"img/jugador-spritesheet.bin",0,1152
;incbin	"img/mono-alto-8x32-0.bin",0,128
;incbin	"img/mono-alto-8x32-2.bin",0,128
;incbin	"img/mono-alto-8x32-3.bin",0,128
spritedatamona:
incbin	"img/mona-alta-8x32.bin",0,128

spritedatamonochico:
incbin "img/mono-comp-8x16.bin", 0, 64

spritedatamonogrande:
incbin "img/enemigo-grande.bin", 0, 256

spritepelota:
  db 00000000b, 00000000b, 00000000b, 00000000b
  db 00000000b, 00101010b, 10101010b, 00000000b
  db 00000000b, 10101010b, 10101010b, 10000000b
  db 00000010b, 10101010b, 10111011b, 10100000b
  db 00001010b, 10101010b, 10101110b, 10101000b
  db 00101010b, 10101010b, 10111011b, 10101010b
  db 00101010b, 10101010b, 10101010b, 10101010b
  db 00101010b, 10101010b, 10101010b, 10101010b
  db 00101010b, 10101010b, 10101010b, 10101010b
  db 00101010b, 01100110b, 10101010b, 10101010b
  db 00101001b, 10011001b, 10101010b, 10101010b
  db 00101010b, 01010110b, 10101010b, 10101010b
  db 00001001b, 10011001b, 10101010b, 10101000b
  db 00000010b, 01100110b, 10101010b, 10100000b
  db 00000000b, 10101010b, 10101010b, 10000000b
  db 00000000b, 00101010b, 10101010b, 00000000b

endspritesgraphics:

tilesgraphicscount:	db	7


align   8,db 0

tilesgraphics:
incbin "img/tile0.bin",0,64
incbin "img/tile1.bin",0,64
incbin "img/tile2.bin",0,64
incbin "img/tile3.bin",0,64
incbin "img/tile4.bin",0,64
incbin "img/tile5.bin",0,64
incbin "img/tile6.bin",0,64

endtilesgraphics:


allocinit: dw memorialibre
allocend: dw memorialibre

section .bss
  ; uninitialized data

memorialibre:

