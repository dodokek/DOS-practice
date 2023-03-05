.model tiny
.code 
.386
org 100h

locals @@


Start:                                   
		cli                             ; disabling interrupts to work with interrupt table
		
		; HOOKING INT 08H

			mov ax, 3508h                       ; finds out segment and offset
			int 21h                             ; of the old 08h handler

			mov word ptr int08h_ptr, bx         ; save old 08h handler
			mov word ptr int08h_ptr + 2, es     ;

			mov ax, 2508h                       ;
			mov dx, offset New08          		; changing 08h handler into my own
			int 21h                             ;

		; HOOKING INT 09H
		
			mov ax, 3509h                       ; finds out segment and offset
			int 21h                             ; of the old 09h handler

			mov word ptr int09h_ptr, bx         ; save old 09h handler
			mov word ptr int09h_ptr + 2, es     ;

			mov ax, 2509h                       ;
			mov dx, offset New09	            ; changing 09h handler into my own
			int 21h                             ;

		sti                         ; allowing interrupts

			mov ax, 3100h           ; terminate and stay resident
			mov dx, offset EOP
			shr dx, 4               ; proper quit for resident progs to solve memory problems
			inc dx                  ; /4 because memory is counted in paragraphs = 16 Bytes
			int 21h       

;------------------------------------------------
;
; Catches 08h interrupt, prints registers 
; and border every tick
;
;------------------------------------------------

New08               proc
					pusha
					push es	; saving registers
					push ds

					push cs ; not fucking up with segments!
					pop  ds


				;--------Code segment---------------------
				push ax bx cx dx				; to print registers

					mov di, offset Output_flag
					cmp byte ptr cs:[di], 1d
					jne @@no_print

				; Tripple bufferisation
					; Compare videomem & draw buffer, transfer
					; changes to savebuffer

					mov bx, 0b800h					; es:[di] = videomem begin
					mov es, bx						
					xor bx, bx
					xor di, di

					mov cx, 0
				@@next:								; comparing all video cells

					mov dx, word ptr es:[di]					; dx = videomem[i]
					cmp word ptr Draw_Buffer[di], dx		; cmp videomem[i], drawbuff[i]
					jne @@no_copy

					mov word ptr Save_Buffer[di], dx					; savebuff[i] = videomem[i]
					add dl, 20
					mov es:[0], dx

				@@no_copy:
					add di, 2

					add cx, 2
					cmp cx, videomem_size
				jle @@next


					mov bx, 0b800h						; printing registers and border to videomem
					mov es, bx
					xor bx, bx
                
					mov al, 1d						; number of border preset
					call border_main

				    mov di, 2* 160d + 120d          ; coords of registers
                    pop dx cx bx ax					; getting regs to print
					call PrintRegs

					;---- Tripple bufferisation					

				
					; Videomem -> draw buffer

					mov bx, 0b800h
					mov es, bx
					xor bx, bx

					mov di, 0
			
					@@L1:
						mov ax, es:[di]
						mov word ptr Draw_Buffer[di], ax

						add di, 2                     ; counter += 1
						cmp di, videomem_size
						jge @@end_loop

						jmp @@L1
					@@end_loop:	


				jmp @@has_print
                @@no_print:

                    pop dx cx bx ax					; removing garbage

				@@has_print:

				;--------Code segment.End---------------------

                    mov al, 20h                     ;
                    out 20h, al                     ;

					pop ds
					pop es
					popa

                    
                    db 0eah
int08h_ptr          dd 0
    

                    iret
                    endp

;------------------------------------------------
;
; Catches 09h interrupt, if shift pressed, changes
; output-flag
;
;------------------------------------------------
New09               proc
					pusha
					push es
					push ds

					push cs ; not fucking up with segments!
					pop  ds

				;---------- Code segment----------------

                    in al, 60h
                    
                    cmp al, 2ah ;(Shift)                ; if to print regs
					jne @@not_pressed

						mov di, offset Output_flag			; if shift, Output flag is reversed
						mov ax, cs:[di]
						not ax
						mov cs:[di], ax
						
						cmp ax, 1d							; if drawing was toggled on before, print save buffer
						je @@no_flush

						; Save buffer -> videomem

						mov bx, 0b800h
						mov es, bx
						xor bx, bx

						mov di, 0
				
						@@L1:
							mov ax, word ptr Save_Buffer[di]
							mov word ptr es:[di], ax

							add di, 2                      ; counter += 2
							cmp di, videomem_size
							jge @@end_loop

							jmp @@L1
						@@end_loop:	

						;-------------------------------

						@@no_flush:
					

                    jmp @@pressed
@@not_pressed:


@@pressed:
				;---------- Code segment.End----------------

                    xor ax, ax                      ;
                    in al, 61h                      ;
                    mov ah, al                      ;
                                                    ;
                    or al, 80h                      ;
                    out 61h, al                     ; this part is for proper
                                                    ; 
                    mov al, ah                      ; dialogue with 09 interrupt
                    out 61h, al                     ;
                                                    ;
                    mov al, 20h                     ;
                    out 20h, al                     ;

					pop ds
					pop es
					popa

                    db 0eah
int09h_ptr			dd 0    

Output_flag			db 1


; Чзх, тройная буферизация, Мама Мия! Но где же тот таинственный третий буфер?

videomem_size = 16d

Draw_Buffer			db videomem_size dup(11d)	; draw buffer in which everything draws instead videomem and after
Save_Buffer			db videomem_size dup(21d)	; save buffer to save everything under the border				
										; being compared with dos window. Then copied to videomem.
										; after comparison any mismatches are transported to save buffer

                    iret
                    endp


;------------------------------------------------
;   Prints some registers on the screen 
;------------------------------------------------
;	Entry:	  Registers: AX, BX, CX, DX
;             DI: coordinates
;	Exit:     None
;	Expects:  ES = 0b800h
;	Destroys: ax, dx, di 
;------------------------------------------------
PrintRegs   proc
            push dx cx bx ax                  ; putting into stack registers to print
            
            pop ax
            mov dx, 160d*4 + 120d            ; setting coordinates

            call PrintHex

            pop bx
            mov ax, bx
            mov dx, 160d*6 + 120d           ; setting coordinates

            call PrintHex

            pop cx
            mov ax, cx
            mov dx, 160d*8 + 120d            ; setting coordinates

            call PrintHex

            pop dx
            mov ax, dx
            mov dx, 160d*10 + 120d            ; setting coordinates

            call PrintHex

            ret
            endp

;----------------------------------------------
; Here are string functions for triple bufferisation
include string_f.asm
;
;-----------------------------------------------

;------------------------------------------------
;	Prints ax register on the screen in hehehex
;------------------------------------------------
;  Entry:		ax = number to print
;				dx = coords on screen
;  Exit:		none
;  Expects:		ES = 0b800h
;  Destroys:	ax, cx, dx, di
;------------------------------------------------

hex_len	= 4d							; len of hex str	

PrintHex		proc
				
				push di					; push (0)

				mov di, hex_len * 2d 	; i = hex_len * 2 + AX
				add di, dx
				std 

				push ax cx dx 			; push (2) (3) (4)

				xor dx, dx				; i = 0

				@@Next:			
                
                mov cx, 0			; shifts counter			

                push dx				; push (5)
                mov  dx, 0			; DX = 0
                
                @@Shift:

				shr ax, 1		; AX /= 2
				jnc @@End

				@@One:
				
				push ax			; push (6)
				mov  ax, 1 		; AX = 0001b
				shl  ax, cl		; DX += 2^CX
				add  dx, ax 
				pop	 ax			; pop  (6)
			
                @@End:
				
				inc cx			; shifts counter ++
				cmp cx, 4d		; if( numShifts == 4 )
				jne @@Shift

                mov cx, ax			; CX = AX
                
                cmp dx, 10d			; if( DX >= 10 )
                jge @@Sym

                @@Digit:
				
				add dx, 48d		; print( DX + '0' )
				mov al, dl		
				jmp @@Print

                @@Sym:			
				
				sub dx, 10		; print( DX - 10 + 'A' )
				add dx, 65d
				mov al, dl

				@@Print:		
                
                pop dx				; pop  (5)

				mov ah, 76d			; black on white

				sub di, 2			; print( ax ) // with 1 sym left( 2 bytes )
				stosw 					
				add di, 2				

				mov ax, cx			; AX = CX

				inc dx				; i++

				cmp dx, hex_len		; if( dx == hex_len )
				jne @@Next

				pop dx cx ax			; pop  (4) (3) (2)
				pop di					; pop  (0)

				ret
				endp


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


;------------------------------------------------
;	Prints ax register on the screen in hehehex
;------------------------------------------------
;  Entry:		al = preset number
;  Exit:		none
;  Expects:     es = ptr to video buffer
;  Destroys:	all
;------------------------------------------------

border_main     proc

                ; mov bx, 0b800h  ; es to videomem
                ; mov es, bx
                ; xor bx, bx

                ; mov ah, 0d      ; clearing the screen
                ; mov al, 0d
                ; call Clear

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
                ; call zoombox
                
                mov bh, byte ptr [si + arr_height]      ; passing coordinates and width
                mov bl, byte ptr [si + arr_width]
                mov dh, byte ptr [si + arr_x]
                mov dl, byte ptr [si + arr_y]

                call draw_border

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
;	Entry:	  dx: dh - x, dl - y
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
                mov ah, [si + arr_fill]      ; adressing to preset array to get color
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
                mov byte ptr es:[di], ch         ; adressing to preset array to get char
                mov byte ptr es:[di + 1], cl     ; adressing to preset array to get color

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

                cmp byte ptr [si], "\"              ; checking if it is user_color symbol
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
; Draws cool animation on border appearance
;------------------------------------------------
;	Entry:	  si - pointer to preset array
;       Exit:     None
;       Expects:  es = 0b800h
;	Destroys: ax, bx, dx, cx
;------------------------------------------------
zoombox         proc

                mov bh, byte ptr [si + arr_height]      ; passing coordinates and width
                mov bl, byte ptr [si + arr_width]
                mov dh, byte ptr [si + arr_x]
                mov dl, byte ptr [si + arr_y]

                cmp bh, bl                              ; zoombox works only on square borders
                jne @@end_l2

                mov ch, bl      ; remembering the orignal width
                shr ch, 1       ; ch / 2
@@next:
                sub bh, 4       ; height - 2
                sub bl, 2       ; width - 2

                add dh, 2       ; x++
                add dl, 2       ; y++

                cmp bl, ch      
                jle @@end_l

                ; mov bp, 1       ; if bp = 1, no text in border

                push bx         ; saving registers
                push dx
                push cx

                call draw_border

                mov cx, 1d      ; wait()
                mov dx, 0ffffh
                mov ah, 86h
                int 15h

                mov ah, 0d      ; clearing the screen
                mov al, 0d
                call Clear
                
                pop cx          ; restoring registers
                pop dx
                pop bx

                jmp @@next
@@end_l:

        
@@next2:
                add bh, 4       ; height - 2
                add bl, 2       ; width - 2

                sub dh, 2       ; x++
                sub dl, 2       ; y++

                cmp bl, byte ptr [si + arr_width]       ; in case width is twice smaller, return
                jge @@end_l2

                ; mov bp, 1       ; if bp = 1, no text in border

                push bx         ; saving registers
                push dx
                push cx

                call draw_border

                mov cx, 1d      ; wait()
                mov dx, 0ffffh
                mov ah, 86h
                int 15h
 
                mov ah, 0d      ; clearing the screen
                mov al, 0d
                call Clear

                pop cx          ; restoring registers
                pop dx
                pop bx

                jmp @@next2
@@end_l2:
                mov ah, 0d      ; clearing the screen
                mov al, 0d
                call Clear

                ret
                endp



preset_size = 48d        ; DONT FORGET TO CHANGE IF AMOUNT OF ATTRS IS CHANGED!
                ;   X    Y    Color Char Width Height FillerChr  FillerClr      ignr   text             ; NO SYMBOLS AFTER $$ FUCKERS!!!
border_0:       db  0d,  0d,    0h,  0h,  0d,   0d,    0d,        0d,           0, 0, "Your advertisment$$"  
border_1:       db  114d, 4d, 34h,  0fh, 10d,  20d,   0d,       45d,           0, 0, "$$"   
border_2:       db   0d, 0d, 0ceh,  40h, 79d,  45d,   11d,       45d,           0, 0, "Goyda goyda goyda$$"    
border_3:       db  14d, 26d, 117d, 30h, 10d,  14d,   46d,       45d,           0, 0, "Meow meow motherfucker$$"  
border_4:       db  40d, 20d, 80d,   3h, 22d,  22d,   12d,       9d,            0, 0, "###S \123\8 marta bi... woman!!!$$"  


user_border:    db 40d dup(1d)
user_text:      db 40d dup(0d)
cmd_buffer:     db 40d dup(0d)
color_buffer:   db 10d dup(0d)


include mainf.asm


EOP:
end                 Start 