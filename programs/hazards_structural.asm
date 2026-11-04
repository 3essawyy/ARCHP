# Structural hazards (TC-205): runs of memory instructions (the MEM stage takes
# the single memory port, fetch stalls), SWAP after loads, back-to-back SWAPs,
# SWAP of a register with itself, SWAP while the MEM stage is busy.
#! expect: R0=11 R1=11 R2=33 R3=11 R4=22 R5=11 R6=22 R7=11 SP=FFF Z=0 N=0 C=0
#! expect: M[FFF]=11 M[FFE]=22 M[FFD]=11 M[200]=11 M[201]=22 OUT=33

.ORG 0
10
.ORG 10
LDM R1, 11
LDM R2, 22
PUSH R1             # M[FFF]=11
PUSH R2             # M[FFE]=22
PUSH R1             # M[FFD]=11
POP R3              # R3=11
POP R4              # R4=22
POP R5              # R5=11
STD R3, 200(R0)     # M[200]=11
STD R4, 201(R0)     # M[201]=22
LDD R6, 200(R0)     # R6=11
LDD R7, 201(R0)     # R7=22
SWAP R6, R7         # right after two loads: R6=22 R7=11
SWAP R6, R7         # back to back: R6=11 R7=22
SWAP R1, R1         # same register: R1 stays 11
PUSH R6             # M[FFF]=11
SWAP R6, R7         # while PUSH occupies the memory: R6=22 R7=11
POP R0              # R0=11
ADD R2, R6, R7      # R2=33
OUT R2
HLT
