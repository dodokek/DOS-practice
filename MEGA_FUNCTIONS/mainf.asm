;------------------------------------------------
;	Prints string
;------------------------------------------------
;	Entry:    string in dx
;	Exit:     not defined
;	Expects:  none
;	Destroys: ah, dx 
;------------------------------------------------

Puts	proc
	
	mov ah, 09h		    ; puts()
	int 21h			    ; by interupting prog, printing the message

	ret
	endp

;------------------------------------------------


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
                mov cx, 80d * 25d

                mov dx, 2500

        @@L1:   mov es:[bx], ax
                add bx, 2
                dec dx
                cmp dx, 0
                jne @@L1

		ret
		endp
;------------------------------------------------


;------------------------------------------------
;   Translates value in register ax to bin format 
;   prints it on the sreen
;------------------------------------------------
;	Entry:	  AX - value to translate, x/y - coordinates
;	Exit:     None
;	Expects:  ES = 0b800h, x != null, y != null
;	Destroys: ax, cx, dx 
;------------------------------------------------
reg2bin         proc
                mov dl, 2d                 ; setting the divider

                call calc_di_print_zeros

@@L1:           div dl          ; dividing the ax             
                add ah, 48d     ; adding to surplus the constant to get ASCII of '0' or '1' 
                
                mov dh, al      ; saving the result of division 

                xchg al, ah      ; swapping al, ah
                mov ah, 00010100b ; setting color and blinking

                stosw           ; mov es:[di], al

                mov al, dh      ; returning the value of the result
                mov ah, 0       ; deleting surplus
                
                cmp al, 0       ; if there is nothing to divide - exit
                jne @@L1

                ret
                endp


;------------------------------------------------
;   Translates value in register ax to bin format 
;   prints it on the sreen
;------------------------------------------------
;	Entry:	  AX - value to translate, 
;             CX: CH - x, CL - y
;	Exit:     None
;	Expects:  ES = 0b800h, x != null, y != null
;	Destroys: ax, cx, dx 
;------------------------------------------------
reg2hex         proc
                mov dl, 16d      ; setting the divider
                
                call calc_di_print_zeros

@@L1:           div dl          ; dividing the ax             
                
                cmp ah, 10
                jge else_1
                    add ah, 48d     ; adding to surplus the constant to get ASCII of 0..9 
                    jmp endif_1
                else_1:
                    add ah, 55d     ; handling A,B,C,D,E,F letters in surplus
                endif_1:

                mov dh, al        ; saving the result of division 
                xchg al, ah       ; swapping al, ah
                mov ah, 00010100b ; setting color and blinking

                stosw           ; mov es:[di], al

                mov al, dh      ; returning the value of the result
                mov ah, 0       ; deleting surplus
                
                cmp al, 0       ; if there is nothing to divide - exit
                jne @@L1

                ret
                endp


;------------------------------------------------
;   Prints dec number on the screen 
;------------------------------------------------
;	Entry:	  AX - value to print
;                x/y - coordinates
;	Exit:     None
;	Expects:  ES = 0b800h, x != null, y != null
;	Destroys: ax, cx, dx 
;------------------------------------------------
reg2dec       proc
                mov dl, 10d                ; setting the divider
                
                call calc_di_print_zeros


@@L1:           div dl          ; dividing the ax             
                add ah, 48d     ; adding to surplus the constant to get ASCII of '0' or '1' 
                
                mov dh, al      ; saving the result of division 

                xchg al, ah      ; swapping al, ah
                mov ah, 00010100b ; setting color and blinking

                stosw           ; mov es:[di], al

                mov al, dh      ; returning the value of the result
                mov ah, 0       ; deleting surplus
                
                cmp al, 0       ; if there is nothing to divide - exit
                jne @@L1

                ret
                endp


;------------------------------------------------
;   Prints num in all formats with given x offset 
;------------------------------------------------
;	Entry:	  AX - value to print
;             CH - X coordinate, CL - Y coordinate
;	Sub function!
;	Expects:  none
;	Destroys: ax, dx 
;------------------------------------------------
threesome       proc
                push ax         ; saving sum for later

                ; coordinates are supposed to be given before
                push cx         ; saving cx cause it is going to be destroyed
                call reg2bin
                pop cx          ; restoring cx
                sub cl, 4d ; moving down a bit for next line

                pop ax    ; storing and restoring for further ops
                push ax

                push cx         ; saving cx cause it is going to be destroyed
                call reg2dec
                pop cx          ; restoring cx
                sub cl, 4d ; moving down a bit for next line

                pop ax    ; restore

                call reg2hex

                ret
                endp

;------------------------------------------------
;   Helping function which upper three functions use 
;------------------------------------------------
;	Entry:	  AX, CX, DI 
;------------------------------------------------

calc_di_print_zeros     proc              
                mov di, 0        ; the size of two words (reg ax) + coordinates offset
                push ax          ; saving ax for later
                
                mov ax, 80d      ; di += y*80
                mul cl
                add di, ax
                
                xchg cl, ch     ; leaving in cx only 00 ch
                mov ch, 0
                add di, cx

                std              ; operand which tells to decrement di each time stosw is called

                push di         ; saving di for later
                mov cl, 8d       ; setting counter
@@next:                  
                mov al, 48d
                mov ah, 00010100b

                stosw

                dec cl
                cmp cl, 0
                jne @@next

                pop di          ; restiring di
                pop ax          ; restoring num to print

                ret
                endp




;------------------------------------------------
;   Reads line from stdin until \n 
;------------------------------------------------
;	Entry:	  keyboard input
;             di - pointer to string to write into
;	Exit:     None
;	Expects:  none
;	Destroys: ax, di 
;------------------------------------------------
getline     proc
            mov ax, 0                   ; preparing ax for double penetration

            mov ah, 01h                 ; going to getch() mode      

@@l1:       
            int 21h                     ; getch()
            cmp al, 0dh                 ; reading until stop symbol
            je @@end

            mov [di], al                ; symb -> memory
            inc di                      ; ptr++
            jmp @@l1
@@end:
            mov byte ptr [di], 024h      ; replace stop sym with endline "$"

            ; mov di, offset mystring
            ; call printline			     ; printing

            ret
            endp


;------------------------------------------------
;   Prints line until special symbol + \n 
;------------------------------------------------
;	Entry:	  di - pointer to string
;	Exit:     None
;	Expects:  not null db
;	Destroys: ax, di 
;------------------------------------------------
printline   proc
            mov ah, 02h                 ; going to putch() mode      

@@l1:       
            mov dl, [di]                ; mobing to dl symbol to print

            cmp dl, "$"                 ; reading until stop symbol "$"
            je @@end
            
            int 21h                     ; getch()

            inc di                      ; ptr++
            jmp @@l1
@@end:
            mov dl, 0dh                 ; puts \n
            int 21h

            ret
            endp



;------------------------------------------------
; Reads the dec number from keyboard and stores it in bl
;------------------------------------------------
;	Entry:	  keyboard input
;             di - pointer to string to write into
;	Exit:     None
;	Expects:  none
;	Destroys: ax, bx, cx, di
;   Returns:  the number read will be stored in AL
;------------------------------------------------


inpt_dec2reg  proc
        mov di, offset mystring     ; reading the num from keyboard
        call getline            
        dec di                      ; moving to the last digit of num

        mov bl, 0           ; preparing ax to store the num
        mov ch, 1           ; setting counter 

@@L1:
        mov bh, [di]        ; moving one digit of the whole num
        sub bh, 48d          ; ascii -> num

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

        cmp di, offset mystring - 1
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
; Reads the bin number from keyboard and stores it in bl
;------------------------------------------------
;	Entry:	  keyboard input
;                 di - pointer to string to write into
;	Exit:     None
;	Expects:  none
;	Destroys: ax, di 
;------------------------------------------------


inpt_bin2reg  proc
        mov di, offset mystring     ; reading the num from keyboard
        call getline            
        dec di                      ; moving to the last digit of num

        mov bl, 0           ; preparing ax to store the num
        mov ch, 1           ; setting counter 

@@L1:
        mov bh, [di]        ; moving one digit of the whole num
        sub bh, 48d          ; ascii -> num

        cmp ch, 1
        je @@skip_one


        mov al, 1d      ; computing 2*n where n is number
        mov cl, ch      ; how many times to pow     

@@next:                 ; pow 2^ch 
        mov ah, 2
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

        cmp di, offset mystring - 1
        jne @@L1

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
; Reads the hex number from keyboard and stores it in bl
;------------------------------------------------
;	Entry:	  keyboard input
;                 di - pointer to string to write into
;	Exit:     None
;	Expects:  none
;	Destroys: ax, di 
;------------------------------------------------


inpt_hex2reg  proc
        mov di, offset mystring     ; reading the num from keyboard
        call getline            
        dec di                      ; moving to the last digit of num

        mov bl, 0           ; preparing ax to store the num
        mov ch, 1           ; setting counter 

@@L1:
        mov bh, [di]        ; moving one digit of the whole num
        
        cmp bh, 65          ; translating 1..9, A..F to dec
        jge @@else_1
                sub bh, 48d     ; adding to surplus the constant to get ASCII of 0..9 
                jmp @@endif_1
        @@else_1:
                sub bh, 55d     ; handling A,B,C,D,E,F letters in surplus
        @@endif_1:
        

        cmp ch, 1
        je @@skip_one


        mov al, 1d      ; computing 16*n where n is number
        mov cl, ch      ; how many times to pow     

@@next:                 ; pow 16^ch 
        mov ah, 16
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

        cmp di, offset mystring - 1
        jne @@L1

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
;	    Entry:	  dx: dh - x, dl - y (top-left corner)
;	              bx: bh - height, bl - width
;       Exit:     None
;	    Expects:  ES: 0b800h
;	    Destroys: ax, bx, cx, dx, di
;       Returns:  the border
;------------------------------------------------
draw_border     proc
                mov ax, 1   ; calculating coordinates of top-left corner 

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
        ; drawing top horizontal
                mov di, ax  ; putting in di the coords of top right corner.
                
                xor cx, cx  ; calculating di
                mov cl, bl
                add di, cx  ; adding width
                std         ; every stosw it will decrement
@@next1:
                mov ah, 00000101b ; giving info which char to put in videomem
                mov al, 11d

                stosw             ; putting another sym in videomem

                pop ax            ; returning the original coords of top left corner
                cmp di, ax        ; exiting the loop in case di in the top left corner
                push ax
                jge @@next1
        ; ----------------------
        ; drawing bottom horizontal
                xor ax, ax      ; ax = 0
                mov al, bh      ; calculating offset for bottom right corner
                mov cx, 80d
                push dx         ; saving dx reg from erasing
                mul cx          ; al  = height * 80
                pop dx
                mov cx, ax      ; storing res in cx

                pop ax          ; getting coords of top-left corn
                push ax         ; А это на новый год
                
                add ax, cx      ; ax = coords of bottom left corn
                mov dx, ax      ; storing coords of bottom left in dx
                
                xor cx, cx      ; cx = 0
                mov cl, bl      ; ax += width
                mov bx, ax      ; storing coords of bottom left in bx
                add ax, cx      ; ax = bottom right corn
                mov di, ax      ; storing coords of bottom right in dx
                
                std         ; every stosw it will decrement
@@next2:
                mov ah, 00000101b ; giving info which char to put in videomem
                mov al, 11d

                stosw             ; putting another sym in videomem

                cmp di, dx        ; exiting the loop in case di in the bottom left corn
                jge @@next2
        ; ----------------------    
        ; drawing left vertical border and, somehow right border also draws, i have zero clue why
                mov di, bx        ; storing in di coords of bottom right corner

@@next3:
                mov byte ptr es:[di], 11d                ; gachi char to videomem
                mov byte ptr es:[di + 1], 00000101b

                sub di, 80d                     ; moving up on one line

                pop ax            ; restoring coords of top left corner
                push ax
                cmp di, ax        ; end of cycle if di is on top left corn
                jge @@next3
        ;-----------------------    

                pop ax
                ret
                endp


;------------------------------------------------
; This function likes to suck dicks, so do I.
;------------------------------------------------
;   Expects: nice cock
;   Destroys: everything
;   Use only in case of extreme lack of cocks in your mouth
;------------------------------------------------

suck_dick       proc
                mov bx, 0b800h
                mov es, bx
                xor bx, bx

                mov bp, 0
@@another_suck:
                mov di, 0
                add di, bp
@@next:
                mov byte ptr es:[di], "S"
                mov byte ptr es:[di + 2], "E"
                mov byte ptr es:[di + 4], "X"
                mov byte ptr es:[di + 6], 0bh

                mov bx, di
                mov cx, bx
                sub ch, 5d
                sub cl, 3d

                ; shl bl, 1
                ; mov bh, 0
                ; add di, bx

                mov byte ptr es:[di + 1], bh
                mov byte ptr es:[di + 3], cl
                mov byte ptr es:[di + 5], bl
                mov byte ptr es:[di + 7], ch

                mov byte ptr es:[3000 - di], "S"
                mov byte ptr es:[3000 - di + 2], "E"
                mov byte ptr es:[3000 - di + 4], "X"
                mov byte ptr es:[3000 - di + 6], 0bh

                mov byte ptr es:[3000 - di + 1], ch
                mov byte ptr es:[3000 - di + 3], bl
                mov byte ptr es:[3000 - di + 5], bh
                mov byte ptr es:[3000 - di + 7], cl

                mov cx, 0d      ; waiting to suck
                mov dx, 0fffh
                mov ah, 86h
                int 15h

                add di, 40d
                cmp di, 3000d
                jle @@next

                add bp, 8
                cmp bp, 32
                jle @@another_suck

                ret
                endp

mystring:   db "CUMCUMCUMCUM$"  ; just a tiny buffer to hold the number