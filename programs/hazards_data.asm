# Data hazards (TC-204): RAW at distances 1-4 on both operands, load-use at
# distances 1-3, load -> store data, load -> address base, POP -> use,
# SWAP results used immediately. No NOPs are needed for correctness; the NOPs
# below only create the distances under test.
#! expect: R0=6 R1=2 R2=1 R3=3 R4=1 R5=15 R6=14 R7=28 SP=FFF Z=0 N=0 C=0
#! expect: M[100]=14 M[101]=14 M[FFF]=14 OUT=2,1

.ORG 0
10
.ORG 10
LDM R1, 5
ADD R2, R1, R1      # distance 1 on both operands: R2=A
ADD R3, R1, R2      # A at distance 2, B at distance 1: R3=F
NOP
ADD R4, R1, R3      # R3 at distance 2 (MEM): R4=14
LDM R5, 1
NOP
NOP
ADD R6, R5, R5      # distance 3 (WB forwarding): R6=2
LDM R7, 3
NOP
NOP
NOP
ADD R0, R7, R7      # distance 4 (register-file bypass): R0=6

LDM R1, 100
STD R4, 0(R1)       # base at distance 1: M[100]=14
LDD R2, 0(R1)       # R2=14
ADD R3, R2, R2      # load-use distance 1: R3=28
LDD R4, 0(R1)
NOP
ADD R5, R4, R4      # load-use distance 2: R5=28
LDD R6, 0(R1)
NOP
NOP
ADD R7, R6, R6      # load-use distance 3: R7=28

LDD R2, 0(R1)       # R2=14
STD R2, 1(R1)       # load -> store data: M[101]=14
LDM R3, 101
LDD R4, 0(R3)       # base from LDM at distance 1: R4=14
PUSH R4             # M[FFF]=14
POP R5              # R5=14
INC R5              # POP -> use at distance 1: R5=15

LDM R1, 1
LDM R2, 2
SWAP R1, R2         # R1=2, R2=1 (sources at distance 1 and 2)
ADD R3, R1, R2      # both SWAP results immediately: R3=3
SUB R4, R1, R2      # R4=1, no borrow
OUT R1              # 2
OUT R2              # 1
HLT
