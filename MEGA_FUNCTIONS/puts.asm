.model tiny
.code

org 100h

Start:

mov dx, offset Msg 	    ; refering to FUCKING SLAVES
int 21h			    ; by interupting prog, printing the message
call Puts

mov ax, 4c00h       ; exit(0)
int 21h

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

Msg: db 0bh, "FUCKING SLAVES", 0bh , "$"    ; the message, followed with directive "db"

end Start