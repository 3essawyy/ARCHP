# Loop with a backward conditional jump taken 31 times (TC-210): the dynamic
# predictor must cut the cycle count compared with static not-taken.
#! expect: R1=20 R2=20 R3=1 R4=0 Z=1 N=0 C=0 OUT=20

.ORG 0
10
.ORG 10
        LDM R1, 0
        LDM R2, 20          # 32 iterations
        LDM R3, 1
loop:   ADD R1, R1, R3
        SUB R4, R1, R2      # negative while R1 < R2
        JN loop             # taken 31 times (clears N)
        OUT R1
        HLT
