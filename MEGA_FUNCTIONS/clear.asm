.model tiny
.code
locals @@

org 100h


start:

mov bx, 0b800h
mov es, bx
mov ax, 0e4b2h

call Clear

mov ax, 4c00h       ; exit(0)
int 21h

ret

include functions.asm

end start