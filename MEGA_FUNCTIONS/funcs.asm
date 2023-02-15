x = 40
y = 20



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
;	Destroys: ax, dx 
;------------------------------------------------
reg2bin         proc
                mov dl, 2d                 ; setting the divider
                mov di, 32 + y*80 + x      ; the size of two words (reg ax) + coordinates offset
                std                        ; operand which tells to decrement di each time stosw is called


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
;	Entry:	  AX - value to translate, x/y - coordinates
;	Exit:     None
;	Expects:  ES = 0b800h, x != null, y != null
;	Destroys: ax, dx 
;------------------------------------------------
reg2hex         proc
                mov dl, 16d                 ; setting the divider
                mov di, 32 + y*80 + x      ; the size of two words (reg ax) + coordinates offset
                std                        ; operand which tells to decrement di each time stosw is called


@@L1:             div dl          ; dividing the ax             
                
                cmp ah, 10
                jge else_1
                    add ah, 48d     ; adding to surplus the constant to get ASCII of 0..9 
                    jmp endif_1
                else_1:
                    add ah, 55d     ; handling A,B,C,D,E,F letters in surplus
                endif_1:

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
;   Prints dec number on the screen 
;------------------------------------------------
;	Entry:	  AX - value to print
;                x/y - coordinates
;	Exit:     None
;	Expects:  ES = 0b800h, x != null, y != null
;	Destroys: ax, dx 
;------------------------------------------------
reg2dec       proc
                mov dl, 10d                 ; setting the divider
                mov di, 32 + y*80 + x     ; the size of two words (reg ax) + coordinates offset
                std                        ; operand which tells to decrement di each time stosw is called


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
;   Reads line from stdin until \n 
;------------------------------------------------
;	Entry:	  keyboard input
;                 di - pointer to string to write into
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
;                 di - pointer to string to write into
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

        mov al, bl

        ;------printing----------------------------

        ; mov al, bl  ; preparing to print the string
        ; mov ah, 0   ; to zero unneded part of ax

        ; mov bx, 0b800h ; to videomem
        ; mov es, bx
        ; xor bx, bx

        ; call reg2dec

        ret
        endp