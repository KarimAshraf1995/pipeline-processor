3
125

LDM R0,3  ; # of occurance of loop
LDM R1,5  ; R1=5
LDM R2,17 ; R2=17
LDM R3,13  ; R3=13
LDM R4,25 ; R4=25
Add R1,R1 ; R1=10 => R1=20 => R1=40 //place of jumping
DEC R0	  ; R0=2 => R0=1 => R0=0
JZ  R2	  ; No jump 2 first then jump
JMP R3
call R4   
LDM R5,27
Jmp R5
Nop
Nop
Nop
Nop
Nop
DEC R1  
RET


.125
RTI
