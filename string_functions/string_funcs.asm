.model tiny
.code
.386
locals @@

org 100h

Start:
        mov di, offset string1
        mov si, offset string2

        call strcmp

        mov ax, 4c00h       ; exit(0)
        int 21h



;------------------------------------------------
;   Compares  2 strings
;------------------------------------------------
;	Entry:	  si: pointer to str1
;                 di: pointer to str2
;       Exit:     None
;	Expects:  nice cock, es = ds
;	Destroys: cx
;       Returns:  Flags will be set according to comparison
;------------------------------------------------
strcmp      proc

@@L1:
            cmp byte ptr [si], "$"      ; in case chars in each string is $, they are equal
            jne @@skip
            cmp byte ptr [di], "$"
            je @@all_eq

            @@skip:

            cmpsb                       ; ds:[si] - es:[di]
            je @@L1                     ; in case of unequality the status of flags is returned
        
            ret                         ; returning flags in last status
@@all_eq:
            cmp ax, ax                  ; setting flags to establish equality
            ret

            endp


;------------------------------------------------
;   Compares n bytes of 2 byte sequences
;------------------------------------------------
;	Entry:	  si: pointer to str1
;                 di: pointer to str2
;                 cx: how many bytes to compare
;       Exit:     None
;	Expects:  nice cock, es = ds
;	Destroys: cx
;       Returns:  Flags will be set according to comparison
;------------------------------------------------
memcmp      proc

            inc cx                      ; adjusting counter
@@L1:
            dec cx                      ; counter--
            cmp cx, 0
            je @@all_eq

            cmpsb                       ; ds:[si] - es:[di]
            je @@L1
        
            ret                         ; returning flags in last status
@@all_eq:
            cmp ax, ax                  ; setting flags to establish equality
            ret

            endp


;------------------------------------------------
;   Fill the specified block of memory with given bytes
;   length is specified
;------------------------------------------------
;	Entry:	  di: pointer to dest
;                 si: pointer to src
;                 cx: how many bytes to copy
;       Exit:     None
;	Expects:  nice cock, es = ds
;	Destroys: cx
;------------------------------------------------
strncpy      proc

@@L1:
            movsb                       ; mov es:[di], ds:[si]
            dec cx                      ; counter--
            cmp cx, 0
            je @@end_loop

            cmp byte ptr ds:[si], "$"   ; cheching endline symbol
            jne @@L1
@@end_loop:
            mov byte ptr es:[di], "$"   ; adding endline symbol

            ret
            endp

;------------------------------------------------
;   Fill the specified block of memory with given bytes
;------------------------------------------------
;	Entry:	  di: pointer to dest
;                 si: pointer to src
;       Exit:     None
;	Expects:  nice cock, es = ds
;	Destroys: destination string (wow!)
;------------------------------------------------
strcpy      proc

@@L1:
            movsb                       ; mov es:[di], ds:[si]

            cmp byte ptr ds:[si], "$"   ; cheching endline symbol
            jne @@L1

            mov byte ptr es:[di], "$"   ; adding endline symbol

            ret
            endp


;------------------------------------------------
;   Fill the specified block of memory with given bytes
;------------------------------------------------
;	Entry:	  di: pointer to string
;                 al: filler byte
;                 cx: how many byte to fill 
;       Exit:     None
;	Expects:  nice cock, es = ds
;	Destroys: bx
;       Returns:  pointer to char or 0 if the latter is not found
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
;  Finds a specified character in the string
;------------------------------------------------
;	Entry:	  di: pointer to string
;                 ah: byte to find
;       Exit:     None
;	Expects:  nice cock
;	Destroys: di
;       Returns:  pointer to char or 0 if the latter
;                 is not found unitl the end of string
;------------------------------------------------
strchr      proc

@@next:
            cmp byte ptr [di], ah   ; if byte is found then returning the ptr to it
            je @@end_loop

            inc di          ; moving to next byte in seq

            cmp byte ptr [di], "$"
            je @@not_found

            jmp @@next
@@not_found:
            mov di, 0       ; if symbol not found then di goes to 0
@@end_loop:


            ret
            endp



;------------------------------------------------
;  Reads a sequence of bytes until the given char
;  or until the given length is reached
;------------------------------------------------
;	Entry:	  di: pointer to string
;                 ah: byte to find
;                 cx: maximum length to find 
;       Exit:     None
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
;       Exit:     None
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



string1:      db "abacaba$     "
string1_twin: db "abacaba$     "

string2:      db "bebra$       "
string2_twin: db "bebra$       "

buffer1:    db 11d dup(60d)
buffer2:    db 11d dup(60d)

end Start