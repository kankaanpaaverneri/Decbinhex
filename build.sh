#bin/bash
nasm -f elf32 -o decbinhex.o decbinhex.asm
ld -m elf_i386 -o decbinhex decbinhex.o
rm *.o
