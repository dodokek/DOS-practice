.286
.model tiny
.code 
org 100h

Start:               
                    xor bx, bx 
                    mov es, bx
                    mov bx, 4*9
                    
                    cli                             ; disabling interrupts to work with interrupt table
                    
                        mov ax, es:[bx]             ; setting jump adress to origin inter func
                        mov Old09Ofs, ax 
                        
                        mov es:[bx], offset New09   ; setting interrupt table addr to out prog
                        
                        mov ax, es:[bx+2]           ; setting segment pointer to original inter func
                        mov Old09Seg, ax

                        mov ax, cs                  ; setting interrupt table segment to code segment
                        mov es:[bx+2], ax

                    sti                         ; allowing interrupts

                        mov ax, 3100h           ; terminate and stay resident
                        mov dx, offset EOP
                        shr dx, 4               ; proper quit for resident progs to solve memory problems
                        inc dx                  ; /4 because memory is counted in paragraphs = 16 Bytes
                        int 21h       


New09               proc
                    push ax bx es di                ; saving all registers from cock sucking
                    push dx cx bx ax                ; putting into stack registers to print

                    xor bx, bx                      ; es -> videomem
                    mov bx, 0b800h                  ;
                    mov es, bx                      ;

                    mov ah, 109d                    ; setting color and coordinate of border
                    mov di, 2* 160d + 120d          ;

                    in al, 60h
                    
                cmp al, 2ah
                jne @@skip_print

                pop ax bx cx dx
                call PrintRegs
                
                pop di es bx ax
                push ax bx es di 

                @@skip_print:

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

                    pop ax bx cx dx                 ; removing regs to print from stack
                    pop di es bx ax                 ; restoring registers
                    
                    db 0eah
Old09Ofs            dw 0
Old09Seg            dw 0     

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
            push dx cx bx

            ; mov ax, ax
            mov di, 160d*4 + 120d            ; setting coordinates

            call reg2hex

            pop bx
            mov ax, bx
            mov di, 160d*6 + 120d           ; setting coordinates

            call reg2hex

            pop cx
            mov ax, cx
            mov di, 160d*8 + 120d            ; setting coordinates

            call reg2hex

            pop dx
            mov ax, dx
            mov di, 160d*10 + 120d            ; setting coordinates

            call reg2hex

            ret
            endp



;------------------------------------------------
;   Translates value in register ax to bin format 
;   prints it on the sreen
;------------------------------------------------
;	Entry:	  AX - value to translate, 
;             DI: coordinates
;	Exit:     None
;	Expects:  ES = 0b800h
;	Destroys: ax, dx, di 
;------------------------------------------------
reg2hex         proc
                mov ah, 0       ; just for now!!!!!!!!!!!!!!!!!!

                mov dl, 16d      ; setting the divider
                
                std

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



EOP:
end                 Start 