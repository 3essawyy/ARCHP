# One-operand instructions (adapted from the TA "OneOperand" program).
# Expected values worked out by hand from the brief + ADR-006.
#! in: 5 10
#! expect: R1=6 R2=FFFFFFF0 Z=0 N=1 C=0 OUT=6,FFFFFFEF,FFFFFFF0 PC=AC SP=FFF

.ORG 0
A0
.ORG A0
NOP            # no change
NOT R1         # R1=FFFFFFFF, N=1 Z=0, C unchanged
INC R1         # R1=0, C=1 N=0 Z=1
IN R1          # R1=5, flags unchanged
IN R2          # R2=10
NOT R2         # R2=FFFFFFEF, N=1 Z=0, C unchanged (1)
INC R1         # R1=6, C=0 N=0 Z=0
OUT R1         # OUT=6
OUT R2         # OUT=FFFFFFEF
SETC           # C=1
INC R2         # R2=FFFFFFF0, C=0 N=1 Z=0
OUT R2         # OUT=FFFFFFF0
HLT            # at AC
