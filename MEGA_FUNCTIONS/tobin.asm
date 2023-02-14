.model tiny
.code
locals @@

org 100h


start:

mov bx, 0b800h  ; travelling to videomemory
mov es, bx

mov ax, 142d     ; the value to translate
x = 50
y = 20
call reg2bin

mov ax, 4c00h       ; exit(0)
int 21h

include funcs.asm

end start