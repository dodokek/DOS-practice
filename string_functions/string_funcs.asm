.model tiny
.code
.386
locals @@

org 100h

Start:
        mov di, offset string1
        call strlen
        
        mov di, offset string1
        mov al, 11d

        call memset

        mov ax, 4c00h       ; exit(0)
        int 21h


;------------------------------------------------
;   Fill the specified block of memory with given bytes
;------------------------------------------------
;	Entry:	  di: pointer to string
;             al: filler byte
;             cx: how many byte to fill 
;   Exit:     None
;	Expects:  nice cock
;	Destroys: bx
;   Returns:  pointer to char or 0 if the latter is not found
;------------------------------------------------
memset      proc
            cld     ; clear directory flag
            mov bx, 0   ; enabling counter

@@L1:
            stosb       ; mov es:[di], al
            inc bx      ; incrementing counter
            cmp bx, cx  ; if counter reaches maximum - exit
            
            jne @@L1


            ret
            endp


;------------------------------------------------
;  Reads a sequence of bytes until the given char
;  or until the given length is reached
;------------------------------------------------
;	Entry:	  di: pointer to string
;             ah: byte to find
;             cx: maximum length to find 
;   Exit:     None
;	Expects:  nice cock
;	Destroys: di, cx
;   Returns:  pointer to char or 0 if the latter is not found
;------------------------------------------------
memchr      proc

@@next:
            cmp byte ptr [di], ah   ; if byte is found then returning the ptr to it
            je @@end_loop

            inc di          ; moving to next byte in seq

            dec cx          ; checking if the max length is exceeded
            cmp cx, 0
            je @@not_found

            jmp @@next
@@not_found:
            mov di, 0       ; if symbol not found then di goes to 0
@@end_loop:


            ret
            endp


;------------------------------------------------
; Counts the length of the string
;------------------------------------------------
;	Entry:	  di: pointer to string
;   Exit:     None
;	Expects:  nice cock
;	Destroys: di, cx
;   Returns:  length of the string in register CX
;------------------------------------------------

strlen      proc

            xor cx, cx              ; cx = 0
@@next:
            cmp byte ptr [di], "$"  ; checking endline symbol 
            je @@endloop

            inc di                  ; ptr++
            inc cx                  ; counter ++
jmp @@next
@@endloop:

            ret
            endp



string1:      db "abacaba$"
string1_twin: db "abacaba$"

string2:      db "bebra$"
string2_twin: db "bebra$"

buffer1:    db 11d dup(60d)
buffer2:    db 11d dup(60d)

end Start