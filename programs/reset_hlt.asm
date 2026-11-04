# Reset vector (PC <- M[0]) and HLT (older instructions complete, nothing after).
#! expect: R1=7 R2=0 OUT=7 PC=42

.ORG 0
40
.ORG 40
LDM R1, 7
OUT R1
HLT
LDM R2, 8        # must not execute
OUT R2
