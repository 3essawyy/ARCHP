# Software interrupts INT 0 / INT 1 and RTI flag restore (ADR-007 context word:
# [31]=C [30]=N [29]=Z, [11:0]=return PC).
#! expect: R2=FFFFFF55 R3=BC Z=1 N=0 C=1 SP=FFF M[FFF]=A0000016 OUT=FFFFFF55,BC

.ORG 0
10
.ORG 2
200              # INT 0 vector
220              # INT 1 vector

.ORG 10
LDM R1, 0        # 10
SUB R1, R1, R0   # 11: Z=1 N=0 C=0
SETC             # 12: C=1  -> flags C N Z = 1 0 1
INT 0            # 13: push A0000014, PC <- M[2]
OUT R2           # 14
INT 1            # 15: push A0000016, PC <- M[3]
OUT R3           # 16
HLT              # 17

.ORG 200
LDM R2, AA
NOT R2           # R2=FFFFFF55, N=1 Z=0
RTI              # flags back to C=1 N=0 Z=1

.ORG 220
LDM R3, BB
INC R3           # R3=BC, flags 000
RTI
