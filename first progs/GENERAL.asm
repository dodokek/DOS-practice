.model tiny
.code
locals @@

org 100h


start:
        mov bx, 0b800h  ; to videomem
        mov es, bx
        xor bx, bx
        
        mov dh, 34d  ; x 
        mov dl, 10d  ; y
        mov bh, 24d  ; height
        mov bl, 80d  ; width
        call draw_border

        mov di, offset first_num   ; reading first number
        call inpt_dec2reg
        mov bx, ax                 ; now first num in bx
        push bx                    ; remembering bx

        mov di, offset second_num  ; reading first number
        call inpt_dec2reg
                                   ; now second num in ax
        pop bx          ; restoring bx
        push ax         ; saving ax for later
        add ax, bx      ; adding bx to ax to print
        
        mov ch, 60d      ; nums x
        mov cl, 26d      ; nums y
        call threesome

        pop ax  ; restoting original value of ax
        push ax ; storing original value
        push bx

        add ax, bx
        mov ch, 80d      ; nums x
        mov cl, 26d      ; nums y
        call threesome

        pop bx
        pop ax           ; restoring value
        
        mul bx
        mov ch, 100d      ; nums x
        mov cl, 26d      ; nums y
        call threesome
        ; params of the border

        mov cx, 200d      ; waiting to suck
        mov dx, 0fffh   ; suck suck suck
        mov ah, 86h
        int 15h
        call suck_dick

        ret

; call inpt_dec2reg

mov ax, 4c00h       ; exit(0)
int 21h


include mainf.asm

first_num: db "CumCumCumCum$"
second_num: db "CumCumCumCum$"

end start