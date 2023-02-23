.model tiny
.code
.386
locals @@

org 100h

;   1    2    3     4    5      6     7           8         9         10        11    
;   X    Y    Color Char Width Height FillerChr  FillerClr UsePreset? Prest_Num Inner_text
; border.com 10.10.20.30.10.30.16.29.12.1.2 

arr_x   = 0d
arr_y   = 1d
arr_clr = 2d
arr_chr = 3d
arr_width = 4d
arr_height = 5d
arr_fill = 6d
arr_fill_clr = 7d
use_preset = 8d
preset_num = 9d
inner_text = 10d
;------------------------------------------

Start:
                call handle_cmd

                mov bx, 0b800h
                mov es, bx
                xor bx, bx

                ; mov ah, 0d      ; clearing the screen
                ; mov al, 0d
                ; call Clear

                mov si, offset user_border

                mov al, byte ptr [si + preset_num]      ; just checking
                xor ax, ax                              ; ax = 0

        cmp byte ptr [si + use_preset], 0               ; cheching if there is option to use preset
        je @@no_preset

                mov al, byte ptr [si + preset_num]      ; now in al the number of preset to load
                mov si, offset border_1                 ; si = ptr to begin of first preset

                mov cl, 1                               ; enabling counter of preset arrays

        @@next:
                cmp al, cl                              ; checking if we are on the right preset
                je @@end_calc_preset

                inc si                                  ; &preset_arrays++
                
                cmp byte ptr [si], "$"                  ; if "$$" is found counter of presets increaces and si moves
                jne @@no_end
                cmp byte ptr [si+1], "$"
                jne @@no_end

                inc cl                                  ; counter of presets ++
                add si, 2d                              ; &preset_array+=2

                @@no_end:

                jmp @@next
        @@end_calc_preset:

        @@no_preset:
                mov bh, byte ptr [si + arr_height]      ; passing coordinates and width
                mov bl, byte ptr [si + arr_width]
                mov dh, byte ptr [si + arr_x]
                mov dl, byte ptr [si + arr_y]


                call draw_border

                mov ax, 4c00h       ; exit(0)
                int 21h


;------------------------------------------------
; Gets border params from cmd line into "user_border" array 
;------------------------------------------------
;	Entry:	  cmd line, not empty ofc
;       Exit:     None
;	Expects:  None
;	Destroys: AX, DI, SI, BP
;       Returns:  values from cmd line stored in the "user_array"
;------------------------------------------------
handle_cmd      proc
                mov bp, 0       ; counter for arguments

                mov di, offset cmd_buffer  ; di now points to buffer
                mov si, 0082h              ; si points to begin of cmd line

@@L1:
                cmp byte ptr [si - 1], 0dh              ; reading cmd_line until \n
                je @@exit_L1

  @@next:
                mov dh, byte ptr [si]      ; dh = arv[n]
                mov byte ptr [di], dh      ; cmd_buffer[i] = argv[j]

                inc si                     ; si++
                inc di                     ; di++

                cmp byte ptr [si], "."     ; Handling the end of argument
                jne @@check
                jmp @@skip_space_if
  @@check:
                cmp byte ptr [si], 0dh     ; cheching if it is the end of cmd line
                jne @@next

@@skip_space_if:
                
                
                mov byte ptr [di], "$"      ; moving endline symbol to cmd_buffer  

                cmp bp, inner_text
                je @@fill_text


                ; translation and storing to user_border
                
                dec di                          ; skipping $
                call str_to_int                 ; translating string stored in cmd_buffer to ax
                mov di, offset user_border      ; storing ax in user border
                add di, bp                      ; moving to cur arg pos
                mov byte ptr [di], al           ; moving to user_prest array another cmd line argument
                
                add bp, 1d                      ; incrementing indx of user preset array 
                
                inc si                          ; skipping space moving to another argv
                mov di, offset cmd_buffer       ; &cmd_buffer = begin

                jmp @@L1
@@exit_L1:
@@fill_text:   ; here i am writing to db "user_text" text from cmd line until 0dh

                mov di, offset cmd_buffer       ; di = &cmd_buffer
                mov si, offset user_border      ; si = &user_border
                add si, inner_text              ; si = user_border[inner_text]
  @@next2:     
                mov ax, [di]                    ; ax = cmd_buffer[i]
                mov [si], ax                    ; user_border[inner_text + i] = ax

                inc di                          ; di++
                inc si                          ; si++

                cmp byte ptr [di-1], "$"          ; copying until the end of cmd_buffer
                jne @@next2

                mov dx, offset user_border      ; returning the pointer to user_border
                call Puts
                ret
                endp


;------------------------------------------------
; Translates string, stored in "cmd_buffer" to dec number
; And stores it in ax 
;------------------------------------------------
;	Entry:	  decimal number laying in buffer
;                 DI - pointer to end of buffer
;       Exit:     None
;	Expects:  None
;	Destroys: AX, BX, CX, DI
;       Returns:  resulting number stored in AX
;------------------------------------------------
str_to_int      proc

                mov bl, 0           ; preparing ax to store the num
                mov ch, 1           ; setting counter 

        @@L1:
                mov bh, [di]        ; moving one digit of the whole num
                sub bh, 48d         ; ascii -> num

                cmp ch, 1
                je @@skip_one


                mov al, 1d      ; computing 10*n where n is number
                mov cl, ch      ; how many times to pow     

        @@next:                 ; pow 10^ch 
                mov ah, 10
                mul ah          ; ---
                dec cl          ; ---
                cmp cl, 1       ; ---
                jne @@next      ; ---

                mul bh          ; k*10^n, k - digit with the cur rank

                mov bh, al      ; storing the result

        @@skip_one:

                add bl, bh      ; adding to ax cur digit * 10^rank

                dec di     ; moving to higher bytes of number
                inc ch     ; increasing counter

                cmp di, offset cmd_buffer - 1
                jne @@L1

                mov al, bl ; storing the result in al
                mov ah, 0d ; clearing ah

                ret
                endp



;------------------------------------------------
; Draws the border on the given coordinates
;------------------------------------------------
;	Entry:	  dx: dh - x, dl - y (top-left corner) - now calculated automaticly to centrate the border
;	          bx: bh - height, bl - width
;                 SI - pointer to preset array
;       Exit:     None
;	Expects:  ES: 0b800h
;	Destroys: ax, bx, cx, dx, di
;       Returns:  the border
;------------------------------------------------
draw_border     proc

                mov ax, 1   ; calculating coordinates of top-left corner 

                mov ch, 0   ; deleting trash
                mov cl, dl  ; * Y
                push dx     ; saving the dx, ignoring the possible overflow
                mul cx
                pop dx      ; returning value of dx

                mov cx, 80d ; * 80
                push dx     ; saving the dx, ignoring the possible overflow
                mul cx
                pop dx      ; returning value of dx

                xor cx, cx  ; cx = 0
                mov cl, dh  ; + X
                add ax, cx    

                push ax     ; pushing the res to have access to it later on.
                call fill_border
                pop ax
                push ax

                mov di, ax              ; storing top-left corner to di for function
                push si                 ; storing si from destroying
                call print_text_border
                pop si
                pop ax
                push ax

                call draw_horizontal

                pop ax          ; printing border symbols
                push ax
                mov di, ax
                mov byte ptr es:[di], 0dah      ; top-left
                xor cx, cx
                mov cl, bl
                add di, cx
                add di, cx
                mov byte ptr es:[di], 0bfh      ; top-right

        ; drawing bottom horizontal
                xor ax, ax      ; ax = 0
                mov al, bh      ; calculating offset for bottom left corner
                mov cx, 80d
                push dx         ; saving dx reg from erasing
                mul cx          ; al  = height * 80
                pop dx
                mov cx, ax      ; storing res in cx
                pop ax          ; getting coords of top-left corn
                
                push ax         ; saving top-left for later

                add ax, cx      ; ax = coords of bottom left corn
                push ax         ; storing coords of bottom left

                
                call draw_horizontal
                
                pop ax          ; printing border symbols
                mov di, ax
                mov byte ptr es:[di], 0c0h      ; bottom-left
                xor cx, cx
                mov cl, bl
                add di, cx
                add di, cx
                mov byte ptr es:[di], 0d9h      ; bottom-right

        ; ----------------------    
                pop ax             ; drawing vertical line from top left corner
                push ax
                
                call draw_vertical

                pop ax            ; drawing vertical line from top right corner
                xor cx, cx         ; adding width to ax
                mov cl, bl
                add cx, cx
                add ax, cx

                call draw_vertical

                ret

                endp

;------------------------------------------------
; Draws horizontal line in border 
;------------------------------------------------
;   Entry:   AX - left point value-coordinates
;            BL - width
;            SI - preset array pointer
;   Expects: es = 0b800h
;   Destroys: AX, CX, DX, DI
;------------------------------------------------
draw_horizontal proc
                mov di, ax  ; putting in di the coords of top right corner.  
                xor cx, cx  ; calculating di
                mov cl, bl  ; cl = width
                add di, cx  ; adding width
                add di, cx  ; adding width again cuz videomem is wider 2 times
                std         ; every stosw it will decrement

                mov cx, ax  ; remembering starting point for comparison
@@next:
                mov ah, [si + arr_clr] ; adressing to preset array to get color
                mov al, [si + arr_chr]  ; adressing to preset array to get char

                stosw             ; mov es:[di], ax

                cmp di, cx        ; exiting the loop in case di in the top left corner
                jge @@next

                ret
                endp


;------------------------------------------------
; Draws horizontal line in border for filler 
;------------------------------------------------
;   Entry:   AX - left point value-coordinates
;            BL - width
;            SI - preset array pointer
;   Expects: es = 0b800h
;   Destroys: AX, CX, DX, DI
;------------------------------------------------
draw_horizontal_fill proc
                mov di, ax  ; putting in di the coords of top right corner.  
                xor cx, cx  ; calculating di
                mov cl, bl  ; cl = width
                add di, cx  ; adding width
                add di, cx  ; adding width again cuz videomem is wider 2 times
                std         ; every stosw it will decrement

                mov cx, ax  ; remembering starting point for comparison
@@next:
                mov ah, [si + arr_fill] ; adressing to preset array to get color
                mov al, [si + arr_fill_clr]  ; adressing to preset array to get char

                stosw             ; mov es:[di], ax

                cmp di, cx        ; exiting the loop in case di in the top left corner
                jge @@next

                ret
                endp

;------------------------------------------------
; Draws horizontal line in border 
;------------------------------------------------
;   Entry:   AX - upper point coordinates
;            BH - height
;            si - preset array pointer
;   Expects: es = 0b800h
;   Destroys: AX, CX, DX, DI
;------------------------------------------------
draw_vertical proc
                push ax         ; storing ax for later                   2

                xor ax, ax      ; ax = 0
                mov al, bh      ; calculating offset for bottom left corner
                mov cx, 80d
                mul cx          ; al  = height * 80
                mov cx, ax      ; storing res in cx
                pop ax          ; getting coords of bottom point         2

                mov di, ax      ; di = coords of top point
                add di, cx      ; di = coords of bottom point

                sub di, 160d    ; excluding corner 1
                add ax, 160d    ; excluding corner 2
                
                mov cl, [si + arr_clr]    ; cl = preset color  
                mov ch, [si + arr_chr]    ; ch = prest symbol

@@next:
                mov byte ptr es:[di], ch  ; adressing to preset array to get char
                mov byte ptr es:[di + 1], cl ; adressing to preset array to get color

                sub di, 160d                     ; moving up on one line

                cmp di, ax        ; end of cycle if di is on top left corn
                jge @@next

                ret
                endp

;------------------------------------------------
; Fills innerside of border with symbol
; draws lines by line
;------------------------------------------------
;	Entry:	  ax: top-left corner
;	          bx: bh - height, bl - width

;       Exit:     None
;	Expects:  ES: 0b800h
;	Destroys: ax, cx
;       Returns:  the border
;------------------------------------------------
fill_border     proc
                mov ch, 1               ; counter for lines

@@next:
                push ax
                push cx
                call draw_horizontal_fill
                pop cx
                pop ax

                add ax, 160
                add ch, 2
                cmp ch, bh
                jle @@next

                ret
                endp


;------------------------------------------------
; Writes text inside the border
;------------------------------------------------
;	Entry:	  di: top-left corner of border
;                 si: pointer to preset array
;	          bx: bh - height, bl - width
;       Exit:     None
;	Expects:  ES: 0b800h
;	Destroys: ax, cx, di, si
;       Returns:  text in the border
;------------------------------------------------
padding_left = 2d

print_text_border     proc
                push bx                ; adjusting padding
                sub bl, 1

                add si, inner_text      ; di = preset_array[inner_text]
                add di, 320d            ; y + 2
                add di, 4d              ; x + 2

                xor cx, cx
                mov cl, padding_left               ; length counter to move string to new line
@@next:

                cmp byte ptr [si], "#"              ; checking if it is newline symbol
                je @@newline

                cmp byte ptr [si], "&"              ; checking if it is user_color symbol
                jne @@no_user_clr

                        push di                             ; saving di

                        mov di, offset color_buffer         ; mov es:[di], hexnumber
                        mov ax, [si + 1]                    ; moving to color_buffer decimal number in form XXX 
                        mov [di], ax
                        mov ah, byte ptr [si + 3]
                        mov byte ptr [di+2], ah 

                        add di, 3                           ; di = end of buffer
                        
                        push bx
                        push cx
                        call str_to_int
                        pop cx
                        pop bx

                        mov ah, al                          ; moving color byte

                        add si, 5d                          ; skipping color code to next cool symbol
                        pop di                              ; restoring di

                        jmp @@user_color

                @@no_user_clr:
                mov ah, 0ceh            ; setting color
                @@user_color:


                mov al, byte ptr [si]   ; ah = preset_array[i]  

                stosw                   ; mov es:[di], ax
 
                add di, 4d              ; next videomem cell, adding 4 because i got flag std and i don't want to change it
                inc cl                  ; incrementing length counter

                cmp cl, bl              ; cheching if string goes out of border
                jne @@no_newline
                @@newline:

                        sub cl, padding_left               ; these 3 ops is basically just \r
                        sub di, cx   
                        sub di, cx            

                        add di, 160d                       ; this is just \n

                        mov cl, padding_left               ; counter to origin position

                @@no_newline:

                inc si                  ; &preset_array++
                cmp byte ptr [si], "$"
                jne @@next


                pop bx
                ret
                endp


;------------------------------------------------
; Calculates dh and dl for top left corner of the border to centrate it
;------------------------------------------------
;	Entry:	  bx: bh - height, bl - width
;       Exit:     None
;	Destroys: CX
;       Returns:  dh - x, dl - y
;------------------------------------------------
centr_border   proc
                ; formula 
                mov dl, 20d     ; y is currently not counting

                ; for x we have formula: x = (160-width) / 2
                mov ch, 120d
                sub ch, bl
                shr ch, 1

                mov dh, ch      ; moving result x coordinate
                ret
                endp



preset_size = 48d        ; DONT FORGET TO CHANGE IF AMOUNT OF ATTRS IS CHANGED!
                ;   X    Y    Color Char Width Height FillerChr  FillerClr      ignr   text             ; NO SYMBOLS AFTER $$ FUCKERS!!!
border_0:       db  0d, 0d,   0h,   0h,  0d,   0d,    0d,         0d,           0, 0, "Your advertisment$$"  
border_1:       db  22d, 20d, 0cbh, 0ch, 20d,  20d,   12d,       45d,           0, 0, "&173&D&165&e&012&d,po&130&pu##mil??$$"   
border_2:       db  20d, 10d, 0ceh, 40h, 14d,  10d,   11d,       45d,           0, 0, "Goyda goyda goyda$$"    
border_3:       db  14d, 26d, 117d, 30h, 10d,  14d,   46d,       45d,           0, 0, "Meow meow motherfucker$$"  


user_border:    db 11d dup(60d)
user_text:      db 12d dup(40d)
cmd_buffer:     db 11d dup(40d)
color_buffer:   db 11d dup(40d)


include ../mainf.asm

end Start