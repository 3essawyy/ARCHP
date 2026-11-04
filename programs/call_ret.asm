# Nested CALL/RET, loops, JN/JC taken and not taken, flag clearing on taken jumps.
#! expect: R1=6 R2=0 R3=1 R4=FFFFFFFF R5=600D SP=FFF Z=0 N=0 C=0 OUT=6

.ORG 0
100
.ORG 100
        LDM R1, 1
        CALL f1          # R1: 1 -> 2 -> 3 -> 6
        OUT R1
        LDM R2, 3
        LDM R3, 1
loop:   SUB R2, R2, R3   # 2, 1, 0
        JZ done          # taken on the third pass (clears Z)
        JMP loop
done:   LDM R4, 2
        SUB R4, R3, R4   # 1-2 = FFFFFFFF: N=1, C=1 (borrow), Z=0
        JN neg           # taken, clears N
        LDM R5, BAD
neg:    JN fail          # not taken (N was cleared)
        JC carry         # taken, clears C
        LDM R5, BAD
carry:  JC fail          # not taken
        LDM R5, 600D
        HLT
fail:   LDM R5, BAD
        HLT

f1:     INC R1
        CALL f2
        SHL R1, 1
        RET
f2:     INC R1
        RET
