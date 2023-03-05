.model tiny
.code 
.386
org 100h

locals @@			
					


Start:                                   
        mov ax, 1111h
        mov bx, 2222h
        mov cx, 3333h
        mov dx, 4444h

@@next:
        push ax
        in   al, 60h  
        cmp  al, 01h
        pop ax
        jne @@next

        mov ax, 4c00h
        int 21h

end                 Start 