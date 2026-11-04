# Hardware interrupts (TC-207). The ISR preserves everything it touches (R1 via
# the stack, flags via RTI) and counts interrupts in R6, so the final state is
# the same wherever the interrupts land; tests/test_interrupts.py also sweeps a
# single INTR pulse over every cycle of this program.
#! intr: 15 40 70
#! expect: R1=24 R2=0 R3=1 R4=23 R5=10 R6=3 SP=FFF Z=0 N=0 C=0 OUT=24

.ORG 0
10
.ORG 1
200                     # hardware-interrupt vector

.ORG 10
        LDM R1, 0
        LDM R2, 8           # loop counter
        LDM R3, 1
loop:   ADD R1, R1, R2      # R1 = 8+7+...+1 = 0x24
        SUB R2, R2, R3
        JZ done
        PUSH R1
        POP R4              # R4 = 0x23 after the last full iteration
        JMP loop
done:   CALL fn
        OUT R1
        HLT
fn:     LDD R5, 0(R0)       # R5 = M[0] = 0x10
        RET

.ORG 200
isr:    PUSH R1
        LDM R1, 0
        SUB R1, R1, R1      # clobber the flags (Z=1); RTI must restore them
        INC R6              # interrupt counter
        POP R1
        RTI
