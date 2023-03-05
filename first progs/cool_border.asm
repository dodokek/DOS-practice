.model tiny
.code
.386
locals @@

org 100h

; border.com 20 30 10 30 16 29 12 1 2 

arr_clr = 0d
arr_chr = 1d
arr_width = 2d
arr_height = 3d
arr_fill = 4d
arr_fill_clr = 5d
use_preset = 6d
preset_num = 7d
inner_text = 8d

preset_size = 6d

Start:

                call handle_cmd

                mov bx, 0b800h
                mov es, bx
                xor bx, bx

                mov ah, 11d
                mov al, 11d
                call Clear

                mov si, offset user_border

                mov al, byte ptr [si + preset_num]      ; just checking
                xor ax, ax                              ; ax = 0

        cmp byte ptr [si + use_preset], 0               ; cheching if there is option to use preset
        je @@no_preset

                mov al, byte ptr [si + preset_num]      ; preset_arr[n]
                mov si, offset border_1                 ; calculating the pointer to preset array
                dec al
                mov ah, preset_size
                mul ah 
                mov ah, 0
                add si, ax                              ; shifting pointer to needed preset

        @@no_preset:
                mov bh, byte ptr [si + arr_height]
                mov bl, byte ptr [si + arr_width]
                mov dh, 10d
                mov dl, 20d


                call draw_border

                mov ax, 4c00h       ; exit(0)
                int 21h


;------------------------------------------------
; Gets border params from cmd line into "user_border" array 
;------------------------------------------------
;	Entry:	  cmd line, not empty ofc
;       Exit:     None
;	Expects:  None
;	Destroys: 
;       Returns:  values from cmd line stored in the "user_array"
;------------------------------------------------
handle_cmd      proc
                mov bp, 0       ; counter for arguments

                mov di, offset cmd_buffer  ; di now points to buffer
                mov si, 0082h              ; si points to begin of cmd line

@@L1:
                cmp byte ptr [si - 1], 0dh              ; reading cmd_line until !
                je @@exit_L1

  @@next:
                mov dh, byte ptr [si]      ; dh = arv[n]
                mov byte ptr [di], dh      ; cmd_buffer[i] = argv[j]

                inc si                     ; si++
                inc di                     ; di++

                cmp byte ptr [si], " "     ; NEED TO HANDLE SPACE AND ENDCMD LINE SYMVOLS!!!
                jne @@check
                jmp @@skip_space_if
  @@check:
                cmp byte ptr [si], 0dh
                jne @@next

@@skip_space_if:
                
                
                mov byte ptr [di], "$"      ; moving endline symbol  
                
                ; translation and storing to user_border
                
                ; mov dx, di      ; cx = len
                ; inc dx          ; skipping $

                dec di                          ; skipping $
                call str_to_int
                mov di, offset user_border      ; storing ax in user border
                add di, bp                      ; moving to cur arg pos
                mov byte ptr [di], al
                
                add bp, 1d                          ; incrementing indx 
                
                inc si                          ; skipping space moving to another argv
                mov di, offset cmd_buffer

                jmp @@L1
@@exit_L1:

                mov dx, offset user_border
                call Puts
                ret
                endp


;------------------------------------------------
; Translates string, stored in "cmd_buffer" to dec number
; And stores it in ax 
;------------------------------------------------
;	Entry:	  decimal number laying in cmd_buffer
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

                ;------printing----------------------------

                ; mov al, bl  ; preparing to print the string
                ; mov ah, 0   ; to zero unneded part of ax

                ; mov bx, 0b800h ; to videomem
                ; mov es, bx
                ; xor bx, bx

                ; call reg2dec

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


;------------------------------------------------
;	Fills the screen with specific symbol
;------------------------------------------------
;	Entry:	  AH = color attr
;		  AL = sym
;	Exit:     None
;	Expects:  ES = 0b800h
;	Destroys: BX, CX
;------------------------------------------------
Clear 		proc
                xor bx, bx

                mov dx, 2500

        @@L1:   mov es:[bx], ax
                add bx, 2
                dec dx
                cmp dx, 0
                jne @@L1

		ret
		endp
;------------------------------------------------



                ;   Color Char Width Height FillerChr  FillerClr
border_1:       db  0cbh, 0ch, 60d,  20d,   10d,       45d    
border_2:       db  0ceh, 40h, 20d,  10d,   11d,       45d    
border_3:       db  0feh, 30h, 10d,  24d,   46d,       45d  
user_border:    db 11d dup(60d)
cmd_buffer:     db 11d dup(40d)


include ../mainf.asm

end Start