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

                    xor bx, bx                      ; es -> vieomem
                    mov bx, 0b800h                  ;
                    mov es, bx                      ;

                    mov ah, 109d                    ; setting color and coordinate of border
                    mov bx, 2* 160d + 120d          ;

                    in al, 60h
                    mov es:[bx], ax
                    
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

                    pop di es bx ax                 ; restoring registers
                    
                    db 0eah
Old09Ofs            dw 0
Old09Seg            dw 0     

                    iret
                    endp

print_reg           proc

                    ret
                    endp


EOP:
end                 Start 