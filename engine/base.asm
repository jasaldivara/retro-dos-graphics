

section .text

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


section .data

allocinit: dw memorialibre
allocend: dw memorialibre

