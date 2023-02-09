; This is my program to which curses on a really low-level

.model tiny   ; Setting the model of operation with memory
.code         ; Saying that this part belongs to code, not data
org 100h      ; Giving number, from which labels will be counted

Dungeon:		    ; Starting suction

mov ah, 02h 		; putch()

mov dl, 0ch		    ; gachi char
int 21h


mov ah, 09h		    ; puts()
mov dx, offset Msg 	; refering to FUCKING SLAVES
int 21h			    ; by interupting prog, printing the message

mov ax, 4c00h		; exit(0)
int 21h


Msg: db 0bh, "FUCKING SLAVES", 0bh , "$"    ; the message, followed with directive "db"

end Dungeon




