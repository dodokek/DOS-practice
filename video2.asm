.model tiny
.code

org 100h

offst = 2150

start:
    mov bx, 0b800h      ; ES <-- video segment
    mov es, bx

    xor bx, bx          ; bx = 0

    mov dx, 0           ; setting the counter in dx
    
    l1:                 ; begin of loop
    mov bx, dx          ; copying to bx order number       
    shl bx, 1		; *2
    add bx, 1980	; shifting to the middle of screen          

    mov cx, dx          ; getting order number  
    add cx, 0080h  	; moving to exact place in cmd line memory
    mov si, cx          ; 
    mov cx, [si]        ; copying byte of cmd line to register

    cmp ch, 0dh         ; checking if there is an end symbol
    je end_l1

    mov byte ptr es:[bx], ch              ; copying value from cmd line to videomem
    and byte ptr es:[bx + 1], 00001100b   ; Setting font color
    or  byte ptr es:[bx + 1], 10100000b   ; enabling blink(first bit), changing background 
    
    inc dx
    jmp l1  ; loop until there is 0dh sybol is found
    end_l1:

    mov ax, 4c00h       ; exit(0)
    int 21h

end start
