# Two-operand instructions (adapted from the TA "TwoOperand" program, extended
# with CMP and the shifts). Carry on SUB/CMP = borrow (ADR-006).
#! in: 5 19 FFFFFFFF FFFFF320
#! expect: R0=0 R1=5 R2=5 R3=5 R4=18 R5=00FFFFFF R6=1F R7=0 Z=0 N=1 C=1

.ORG 0
FF
.ORG FF
IN R1             # R1=5
IN R2             # R2=19
IN R3             # R3=FFFFFFFF
IN R4             # R4=FFFFF320
MOV R5, R3        # R5=FFFFFFFF, flags unchanged
ADD R4,R1,R4      # R4=FFFFF325, C=0 N=1 Z=0
SUB R6,R5,R4      # R6=00000CDA, no borrow: C=0 N=0 Z=0
AND R4,R7,R4      # R4=0, Z=1 N=0, C unchanged
IADD R2,R2,FFFF   # R2=19+(-1)=18, carry-out=1: C=1 N=0 Z=0
SWAP R2, R4       # R2=0, R4=18
ADD R2,R1,R2      # R2=5, C=0 N=0 Z=0
ADD R6,R4,R2      # R6=1D
IADD R6, R6, 2    # R6=1F
AND R3, R2, R6    # R3=5
CMP R1, R2        # 5-5=0: Z=1 N=0 C=0
SHL R5, 4         # R5=FFFFFFF0, C=last bit out=1, N=1 Z=0
SHR R5, 8         # R5=00FFFFFF, N=0 Z=0, C unchanged (1)
SHL R1, 0         # R1=5, Z=0 N=0, C unchanged (shift by 0)
CMP R1, R6        # 5-1F: borrow C=1, N=1, Z=0
HLT
