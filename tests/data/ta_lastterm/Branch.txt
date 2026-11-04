# all numbers in hex format
# we always start by reset signal
# this is a commented line
# You should ignore empty lines

# ---------- Don't forget to Reset before you start anything ---------- #

.ORG 0           #this means the the following line would be  at address  0 , and this is the reset address
10

.ORG 2           #this hw interrupt handler
900

.ORG 900 #this is hw int
IN R7 		 #R7=5
AND R0,R0,R0     #N=0,Z=1
OUT R3
RTI              #POP PC and flags restored
IADD R1, R2, R3  #Try Hardware interrupt when fetching this (in a second run) - infinite loop?

.ORG 10
IN R1            #R1=30
IN R2            #R2=50
IN R3            #R3=100
IN R4            #R4=300
Push R4          #SP=FFE, M[FFF]=300
JMP 30           #taken
INC R1	         #this statement shouldn't be executed
 
#check flag fowarding  
.ORG 30
AND R5,R1,R5     #R5=0 , Z = 1
JZ  50           #Jump taken, Z = 0
SETC             #this statement shouldn't be executed, C-->1

#check on flag updated on jump
.ORG 50
JZ 30            #shouldn't be taken

# Check on flag updated on ALU operations
NOT R5           #R5=FFFF_FFFF, Z= 0, C--> not change, N=1
SUB R7, R5, R5   #Z=1, N=0
IN R1            #R1=60
JZ 60            #jump taken, Z=0
ADD R1, R2, R3   #should not be executed

.ORG 60
IN R1            #R1=70
JZ 70            #jump not taken
JMP 70           #jump taken & TEST prediction=false then unconditional jump
inc r1           #should not be executed 

# Load use
.ORG 70
IADD R1, R1, 10  #R1=80
SUB R7, R1, R1   #Z=1, N=0
PUSH R1          #SP=FFD, M[FFE]=80
POP R1           #SP=FFE, R1=80
JZ 80            #Taken
INC R1 		 #try hardware interrupt when fetching this

.ORG 80
#check destination forwarding
IN  R6           #R6=700, flag no change
JMP 700          #jump taken

#check on load use
.ORG 700
ADD R7, R0, R1   #R7=80
POP R6           #R6=300, SP=FFF, try hardware interrupt here
Call 300         #SP=FFE, M[FFF]=next PC
INC R6	         #R6=401, this statement shouldn't be executed till call returns, C--> 0, N-->0, Z-->0
NOP
NOP
HLT

.ORG 300
ADD R6,R3,R6     #R6=400
ADD R1,R1,R2     #R1=D0, C->0, N=0, Z=0
RET
ADD R1, R1, R1   #this shouldnot be executed - try hardware interrupt when this is at fetch

.ORG 500
NOP
NOP
