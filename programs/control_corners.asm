# Control-hazard corner cases (TC-206):
#  * flag produced by the instruction right before the jump (no flag forwarding
#    needed: CCR is written in EX1 and read in EX2)
#  * wrong-path HLT behind a taken jump must NOT halt the processor
#  * taken jump clears its flag; the same jump right after is not taken
#  * JMP right after a branch; CALL of an empty function; callee with stack ops
#! expect: R0=7 R1=0 R2=5 R3=7 R4=9 R5=1 R6=3 R7=0 SP=FFF Z=0 N=0 C=0 OUT=5 M[FFE]=7

.ORG 0
10
.ORG 10
        SUB R1, R1, R1      # R1=0, Z=1
        JZ a                # taken (Z from the previous instruction), Z <- 0
        HLT                 # wrong path: must not halt
a:      LDM R2, 5
        OUT R2
        SETC                # C=1
        JC b                # taken, C <- 0
        HLT                 # wrong path
b:      JC fail             # not taken (C was cleared)
        JMP c               # JMP right after a branch
        HLT
c:      CALL empty          # returns immediately
        LDM R3, 7
        CALL f              # R4 = 7 + 2
        LDM R5, 1
        JZ fail             # Z=0 after f's ADD
        JN fail
        LDM R6, 3
        HLT
fail:   LDM R7, BAD
        HLT

empty:  RET
f:      PUSH R3             # M[FFE]=7 (M[FFF] holds the return address)
        LDM R4, 2
        POP R0              # R0=7
        ADD R4, R0, R4      # R4=9, Z=0 N=0 C=0
        RET
