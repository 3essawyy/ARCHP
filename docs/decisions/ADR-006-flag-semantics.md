# ADR-006: Flag semantics and timing

- **Status:** Accepted
- **Date:** 2026-11-04
- **Session:** S001
- **Related:** REQ-G3, REQ-I2, REQ-I5…I8, REQ-I12

## Context
The brief lists which instructions update Z/N/C, but leaves the carry meaning for subtraction, shift details and the conditional-jump flag clearing open.

## Decision
- **Z/N** are updated by NOT, INC, ADD, SUB, AND, IADD, CMP, SHR, SHL (N = result bit 31).
- **C** rules:
  - ADD, IADD, INC: carry-out.
  - SUB, CMP: **borrow** (C = 1 iff A < B unsigned).
  - SHL by n≠0: the last bit shifted out (`A[32−n]`).
  - SHL by 0: C unchanged.
  - SETC: C = 1.
  - SHR: **never** changes C (as written in the brief).
- Shift amount = `Imm[4:0]`; SHR is logical.
- MOV, SWAP, LDM, LDD, POP, IN, OUT, PUSH, STD and the jumps (except below) don't touch flags.
- **JZ/JN/JC clear the tested flag only when the jump is taken.**
- **Timing:** CCR is written at the end of EX1 and read by JZ/JN/JC in EX2 and by INT/interrupt pushes in EX2. Every older writer has passed EX1 by then, so no flag forwarding is needed. When a jump clears a flag in EX2 and the younger instruction in EX1 writes flags in the same cycle, the younger write wins for the bits it writes. RTI restores flags in WB.

## Alternatives considered
| Option | Why not |
|---|---|
| ARM-style C = no-borrow | Counter-intuitive for test writers |
| SHR updates C | Not in the brief; the TA's tests follow the brief |
| Flags written in WB | Would need flag forwarding to EX2 |

## Evidence and risk (added 2026-11-04, T-003)
- **Last term's TA comment disagrees.** `TwoOperand.txt` comments `SUB R6,R5,R4` (FFFFFFFF − FFFFF325) as "C-->1 … carry as not borrow".
- **Last term's implementation agrees with us.** The reference ALU (`six-stage-pipeline-processor/src/components/alu.vhd`) sets C = unsigned borrow for SUB.
- **User rule:** if the brief is silent, follow last term's implementation. So **C = borrow stands**.
- **Mitigation:** the convention is one constant: `SUB_CARRY_IS_BORROW` in `archp.golden` and `C_SUB_CARRY_IS_BORROW` in `archp_pkg`. If the TA asks for the other convention, flipping both constants switches it.

## Consequences
The golden model implements exactly these rules; test programs assert them.
