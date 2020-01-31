#!/bin/sh

dd if=/dev/zero of=~/midisco.img bs=512 count=1440
mkfs.msdos -F 12 -n "PROGRAMAS" -D 0x00 -v ~/midisco.img
mcopy -i ~/midisco.img ./bin/*.* ::
mdir -i ~/midisco.img


