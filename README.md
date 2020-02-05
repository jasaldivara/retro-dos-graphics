# retro-dos-graphics

Various routines for programming graphics and games on MSDOS and PC-compatible 16-bit systems

Assembly code for 8086 CPU

This is a work in progress

This project includes functions for drawing sprites on screen in CGA graphic modes:

  * mid-res 320 x 200 pixels in 4 colors
  * low-res 160 x 200 pixels in 16 colors composite video mode

Other graphic modes, such as Tandy 1000 Graphics will be supported in the future.

More functionality included:
  * Keyboard interrupt handler
  * Using the PC Speaker for playing music
  
For generating MSDOS executables, you need NASM. (I don't know if it works with other assemblers)
A makefile is included for building the project with Make


This project has been tested on DosBox and PCem


