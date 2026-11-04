# Branches, flag clearing, CALL/RET (adapted from the TA "Branch" program;
# interrupts are exercised separately in interrupt.asm).
#! in: 30 50 100 300 60 70 700
#! expect: R0=0 R1=D0 R2=50 R3=100 R4=300 R5=FFFFFFFF R6=401 R7=80
#! expect: SP=FFF M[FFF]=703 M[FFE]=80 Z=0 N=0 C=0

.ORG 0
10

.ORG 10
IN R1            # R1=30
IN R2            # R2=50
IN R3            # R3=100
IN R4            # R4=300
PUSH R4          # SP=FFE, M[FFF]=300
JMP 30           # taken
INC R1           # must not execute

.ORG 30
AND R5,R1,R5     # R5=0, Z=1
JZ  50           # taken, Z=0
SETC             # must not execute

.ORG 50
JZ 30            # not taken (Z=0)
NOT R5           # R5=FFFFFFFF, Z=0 N=1
SUB R7, R5, R5   # Z=1 N=0 C=0
IN R1            # R1=60
JZ 60            # taken, Z=0
ADD R1, R2, R3   # must not execute

.ORG 60
IN R1            # R1=70
JZ 70            # not taken
JMP 70           # taken
INC R1           # must not execute

.ORG 70
IADD R1, R1, 10  # R1=80
SUB R7, R1, R1   # Z=1 N=0
PUSH R1          # SP=FFD, M[FFE]=80
POP R1           # SP=FFE, R1=80
JZ 80            # taken
INC R1           # must not execute

.ORG 80
IN  R6           # R6=700
JMP 700          # taken

.ORG 700
ADD R7, R0, R1   # R7=80
POP R6           # R6=300, SP=FFF
CALL 300         # M[FFF]=703, SP=FFE
INC R6           # after RET: R6=401, Z=0 N=0 C=0
NOP
NOP
HLT

.ORG 300
ADD R6,R3,R6     # R6=400
ADD R1,R1,R2     # R1=D0
RET
ADD R1, R1, R1   # must not execute
