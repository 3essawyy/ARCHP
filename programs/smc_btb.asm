# Self-modifying code vs. the dynamic predictor (TC-210 corner case):
# pass 1 takes the JZ at X (the BTB allocates it as "taken"), then overwrites X
# with a NOP. In pass 2 the BTB still predicts X as a taken jump; decode must see
# it is a NOP and send fetch back to X+1 so INC R1 executes.
#! expect: R1=1 R2=0 OUT=1 M[3F]=1

.ORG 0
10
.ORG 10
        LDM R1, 0
        LDM R2, 2
        LDM R4, X
        LDM R6, 1
top:    SUB R3, R3, R3      # Z=1
X:      JZ skip             # pass 1: taken; pass 2: overwritten with NOP
        INC R1              # runs only in pass 2
skip:   STD R0, 0(R4)       # M[X] <- 0 (NOP)
        SUB R2, R2, R6
        JZ end
        JMP top
end:    OUT R1
        STD R1, 3F(R0)      # M[3F] = 1
        HLT
