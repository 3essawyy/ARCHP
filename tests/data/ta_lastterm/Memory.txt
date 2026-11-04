# all numbers in hex format
# we always start by reset signal
# this is a commented line
# You should ignore empty lines

# ---------- Don't forget to Reset before you start anything ---------- #

.ORG 0  #this means the the following line would be  at address  0 , and this is the reset address
300

.ORG 300

IN R2            #R2=19 add 19 in R2
IN R3            #R3=FFFFFFFF
IN R4            #R4=FFFFF320
LDM R1,5         #R1=5
PUSH R1          #SP=FFE,M[FFF]=5
PUSH R2          #SP=FFD,M[FFE]=19
POP R1           #SP=FFE,R1=19
POP R2           #SP=FFF,R2=5

# Load use & Memory to ALU
ADD R5, R2, R1   #R5=1E

IN R5            #R5=10
STD R2,200(R5)   #M[210]=5  (address is hexa)

STD R1,201(R5)   #M[211]=19 (address is hexa)
LDD R3,201(R5)   #R3=19
LDD R4,200(R5)   #R4=5

# Load use & memory to ALU
ADD R5, R4, R3   #R5=1E

# Load use & Load use at load & mem2alu
IN R5            #R5= 10
IN R2            #R2=19
STD R4, 200(R2)  #M[219]=5
LDD R3, 201(R5)  #R3=19
LDD R2, 200(R3)  #R2=5
ADD R2, R2, R3   #R2=1E

HLT