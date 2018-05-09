3
125

LDM R0,3  ; # of occurance of loop, 0-1
LDM R1,5  ; R1=5, 3-4
LDM R2,12 ; R2=12, 5-6
LDM R3,8  ; R3=8, 7-8
LDM R4,20 ; R4=20, 9-10
Add R1,R1 ; R1=10, 11
DEC R0	  ; R0=2, 12
JZ  R2	  ; no jmp here, 13
JMP R3	  ; jmp to LDM R4,20 , 14
call R4   ; call , 15
LDM R5,22 ; 16-17,
Jmp R5    ; 17-
Nop
Nop
Nop
Nop
Nop
DEC R1  
RET


.125
RTI
