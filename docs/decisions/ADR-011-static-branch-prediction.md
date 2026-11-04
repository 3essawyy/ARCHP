# ADR-011: Static prediction — not-taken for JZ/JN/JC; JMP/CALL redirect in decode

- **Status:** Accepted
- **Date:** 2026-11-04
- **Session:** S001
- **Related:** REQ-P1-4, REQ-E5 (control hazards), REQ-E7

## Context
The brief puts branch resolution in Execute-2. The ranked build must use static prediction.

## Decision
- **JZ/JN/JC:** predicted not-taken; fetch falls through. EX2 tests CCR. If taken:
  1. flush ID and EX1 (their writes are suppressed in the same cycle);
  2. clear the tested flag;
  3. redirect fetch to `imm[11:0]`.
  Penalty: 2 cycles.
- **JMP/CALL:** the target is an immediate in the instruction word, which is available in the decode cycle, so the fetch address is steered in the **same** cycle (0 penalty). CALL also issues a push micro-op.
- **RET/RTI:** decode stops fetching (`wait`) until the popped PC arrives in WB.

## Alternatives considered
| Option | Why not |
|---|---|
| Predict taken in decode | Needs PC+1 recovery path; more area in the ranked build |
| Resolve JMP in EX2 too | 2 cycles lost on every JMP/CALL |

## Consequences
The combinational path RAM data → decode → fetch-address mux → RAM address register is the critical path. Timing is not graded; this is acceptable.
