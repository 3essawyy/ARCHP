# Memory and stack instructions (adapted from the TA "Memory" program; includes
# load-use cases). Offsets are hex; negative offset wraps inside 4K.
#! in: 19 FFFFFFFF FFFFF320 10 10 19
#! expect: R1=19 R2=1E R3=19 R4=5 R5=10 R6=FFFF R7=FFFF SP=FFF Z=0 N=0 C=0
#! expect: M[210]=5 M[211]=19 M[219]=5 M[F]=FFFF M[FFF]=5 M[FFE]=19

.ORG 0
300
.ORG 300
IN R2            # R2=19
IN R3            # R3=FFFFFFFF
IN R4            # R4=FFFFF320
LDM R1,5         # R1=5
PUSH R1          # M[FFF]=5, SP=FFE
PUSH R2          # M[FFE]=19, SP=FFD
POP R1           # SP=FFE, R1=19
POP R2           # SP=FFF, R2=5
ADD R5, R2, R1   # load-use: R5=1E
IN R5            # R5=10
STD R2,200(R5)   # M[210]=5
STD R1,201(R5)   # M[211]=19
LDD R3,201(R5)   # R3=19
LDD R4,200(R5)   # R4=5
ADD R5, R4, R3   # load-use: R5=1E
IN R5            # R5=10
IN R2            # R2=19
STD R4, 200(R2)  # M[219]=5
LDD R3, 201(R5)  # R3=M[211]=19
LDD R2, 200(R3)  # load-use into address: R2=M[219]=5
ADD R2, R2, R3   # R2=1E
LDM R6, FFFF     # zero-extended: R6=0000FFFF
STD R6, -1(R5)   # M[F]=FFFF
LDD R7, -1(R5)   # R7=FFFF
HLT
