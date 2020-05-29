
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>


void mostrar_ayuda();
void rorgspritesheet(FILE *fo, FILE *fd, int sw, int sh, int sc);

/*
 * @Params
 * fo => Archivo de origen
 * fd => Archico destino
 * sw => Sprite Width, in bytes
 * sh => Sprite Height, in pixels
 * sc => Sprite count
 *
 */


const char *uso = "Uso: rospritesheet archivo_origen -sw NUM -sh NUM -sc NUM -o archivo_destino\n";

int main (int argc, char *argv[])
{
  FILE *forigen = NULL, *fdestino = NULL;
  unsigned int sw = 0, sh = 0, sc = 0;

  if (argc > 1){
    if (argv[1][0] != '-'){
      forigen = fopen(argv[1], "rb");
      if (forigen == NULL){
        fprintf(stderr, "Error al abrir archivo de origen.\n");
        fprintf(stderr, uso);
        return EXIT_FAILURE;
      }
    }
  }

  for (int i = 0; i < argc; ++i)
  {
      /* printf("argv[%d]: %s\n", i, argv[i]); */
    if ((strcmp (argv[i], "-h") == 0) || (strcmp (argv[i], "--help") == 0)){
      mostrar_ayuda();
      return EXIT_SUCCESS;
    }

    if ((strcmp (argv[i], "-o") == 0) || (strcmp (argv[i], "-O") == 0)){
      /* Establecer archivo de salida */
      if (argc > i + 1){
        fdestino = fopen(argv[i + 1], "wb");
        if (fdestino == NULL){
          fprintf(stderr, "Error al abrir archivo destino.\n");
          fprintf(stderr, uso);
          return EXIT_FAILURE;
        }
      } else {
        fprintf(stderr, "Error: Se usa bandera -o, pero no se establece archivo de salida.\n");
        fprintf(stderr, uso);
        return EXIT_FAILURE;
      }
    }

    if (strcmp (argv[i], "-sw") == 0){
      /* Establecer archivo de salida */
      if (argc > i + 1){
        errno = 0;
        sw = strtol(argv[i + 1], NULL, 10);
        if (errno != 0){
          fprintf(stderr, "Error: Se usa argumento -sw, pero no se reconoce como numero.\n");
          fprintf(stderr, uso);
          return EXIT_FAILURE;
        }
        if (sw <= 0){
          fprintf(stderr, "Error: Valor de -sw debe ser mayor a cero.\n");
          fprintf(stderr, uso);
          return EXIT_FAILURE;
        }
        /* printf("SW: %d \n", sw); */
      } else {
        fprintf(stderr, "Error: Se usa argumento -sw, pero no se establece su valor.\n");
        fprintf(stderr, uso);
        return EXIT_FAILURE;
      }
    }

    if (strcmp (argv[i], "-sh") == 0){
      /* Establecer archivo de salida */
      if (argc > i + 1){
        errno = 0;
        sh = strtol(argv[i + 1], NULL, 10);
        if (errno != 0){
          fprintf(stderr, "Error: Se usa argumento -sh, pero no se reconoce como numero.\n");
          fprintf(stderr, uso);
          return EXIT_FAILURE;
        }
        if (sh <= 0){
          fprintf(stderr, "Error: Valor de -sh debe ser mayor a cero.\n");
          fprintf(stderr, uso);
          return EXIT_FAILURE;
        }
        /* printf("SW: %d \n", sw); */
      } else {
        fprintf(stderr, "Error: Se usa argumento -sh, pero no se establece su valor.\n");
        fprintf(stderr, uso);
        return EXIT_FAILURE;
      }
    }

    if (strcmp (argv[i], "-sc") == 0){
      /* Establecer archivo de salida */
      if (argc > i + 1){
        errno = 0;
        sc = strtol(argv[i + 1], NULL, 10);
        if (errno != 0){
          fprintf(stderr, "Error: Se usa argumento -sc, pero no se reconoce como numero.\n");
          fprintf(stderr, uso);
          return EXIT_FAILURE;
        }
        if (sc <= 0){
          fprintf(stderr, "Error: Valor de -sc debe ser mayor a cero.\n");
          fprintf(stderr, uso);
          return EXIT_FAILURE;
        }
        /* printf("SW: %d \n", sw); */
      } else {
        fprintf(stderr, "Error: Se usa argumento -sh, pero no se establece su valor.\n");
        fprintf(stderr, uso);
        return EXIT_FAILURE;
      }
    }
  }
  if (sw <= 0){
    fprintf(stderr, "Error: No se ha especificado valor -sw.\n");
    fprintf(stderr, uso);
    return EXIT_FAILURE;
  }
  if (sh <= 0){
    fprintf(stderr, "Error: No se ha especificado valor -sh.\n");
    fprintf(stderr, uso);
    return EXIT_FAILURE;
  }
  if (sc <= 0){
    fprintf(stderr, "Error: No se ha especificado valor -sc.\n");
    fprintf(stderr, uso);
    return EXIT_FAILURE;
  }
  if (! forigen){
    fprintf(stderr, "Error: No se ha establecido archivo de origen.\n");
    fprintf(stderr, uso);
    return EXIT_FAILURE;
  }
  if (! fdestino){
    fprintf(stderr, "Error: No se ha establecido archivo destino.\n");
    fprintf(stderr, uso);
    return EXIT_FAILURE;
  }

  printf("Sprite Width:  %d\n", sw);
  printf("Sprite Height: %d\n", sh);
  printf("Sprite Count:  %d\n", sc);

  rorgspritesheet(forigen, fdestino, sw, sh, sc);
}


void mostrar_ayuda(){
  printf("Reorganiza Sprite Sheet\n");
  printf("\n");
  printf("Este programa reorganiza los datos de un mapa de bits correspondiente a un spritesheet en el que originalmente los sprites estaban organizados de forma horizontal (y por lo tanto sus bits estaban interlazados). Dichos datos cambian de formato, para que los sprites aparezcan en forma vertical, y de esta forma ya no estarán interlazados.\n");
  printf("\n");
  printf("-sw: Ancho de sprite en bytes.\n");
  printf("-sh: Altura de sprite en bytes.\n");
  printf("-sc: Cantidad de sprites en spritesheet.\n");

  return;
}

void rorgspritesheet(FILE *fo, FILE *fd, int sw, int sh, int sc)
{
  int byte_lectura;

  for (int s = sc; s > 0; s--)
  {
    for (int l = sh; l > 0; l --)
    {
      for (int b = sw; b > 0; b--)
      {
        byte_lectura = fgetc(fo);

        if (byte_lectura == EOF){
          fprintf(stderr, "Error: Final del archivo inesperado.\n");
          exit(EXIT_FAILURE);
          return;

        } else {
          putc (byte_lectura, fd);
        }
      }
      fseek (fo, ((sc - 1 ) * sw), SEEK_CUR);
    }
    fseek (fo, ((-1 * sw * sc * sh) + sw), SEEK_CUR);
  }
}

