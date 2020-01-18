

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void mostrar_ayuda();
void p8bt4b(FILE *fo, FILE *fd);


const char *uso = "Uso: p8bt4b archivo_origen -o archivo_destino\n";


int main (int argc, char *argv[])
{
  FILE *forigen, *fdestino;

  for (int i = 0; i < argc; ++i)
  {
      /* printf("argv[%d]: %s\n", i, argv[i]); */
    if ((strcmp (argv[i], "-h") == 0) || (strcmp (argv[i], "--help") == 0)){
      mostrar_ayuda();
      return EXIT_SUCCESS;
    }
  }

  if (argc < 4){
    fprintf(stderr, "Número de argumentos insuficientes\n");
    fprintf(stderr, uso);
    return EXIT_FAILURE;
  }

  if ((strcmp (argv[2], "-o") != 0) && (strcmp (argv[2], "-O") != 0)){
    fprintf(stderr, "Formato de argumentos incorrecto\n");
    fprintf(stderr, uso);
    return EXIT_FAILURE;
  }

  forigen = fopen(argv[1], "rb");
  if (forigen == NULL){
    perror("Error al abrir archivo de origen");
    return EXIT_FAILURE;
  }

  fdestino = fopen(argv[3], "wb");
  if (fdestino == NULL){
    perror("Error al abrir archivo destino");
    return EXIT_FAILURE;
  }

  p8bt4b(forigen, fdestino);

  /* Cerrar archivos */
  fclose (forigen);
  fclose (fdestino);
  return EXIT_SUCCESS;
}

void mostrar_ayuda(){
  printf("Pack 8 Bits To 4 Bits\n");
  printf("\n");
  printf("Este programa empaqueta secuencias de bytes tomando unicamente sus ultimos 4 bits, de forma que por cada dos bytes en el archivo de origen, queda un byte en el archivo destino\n");
  printf("\n");
  printf("Esto puede ser util para convertir 'datos de imagen en bruto' exportados desde GIMP en un formato de imagen empaquetada de cuatro bits compatible con CGA composite o Tandy de 16 colores.\n");

  return;
}

void p8bt4b(FILE *fo, FILE *fd){
  /* Procesar archivos aquí */
  signed int posicion = 1;
  int byte_lectura;
  char byte_escritura = 0;

  while ((byte_lectura = getc(fo)) != EOF){
    /* printf("Leyendo: %x\n", byte_lectura); */

    byte_lectura &= 0xf;  /* Tomar en cuenta sólo los dos ultimos bits */
    byte_lectura <<= (posicion * 4);   /* Recorrer bits de acuerdo a la posición */
    byte_escritura |= byte_lectura;    /* Agregar bits en byte de escritura */

    /* printf("Byte lectura procesado: %x\n", byte_lectura); */

    if (posicion == 0){
      posicion = 1;
      /* printf ("Escribir: %x\n", byte_escritura); */
      putc (byte_escritura, fd);
      byte_escritura = 0;
    } else {
      posicion --;
    }
  }



  return;
}

