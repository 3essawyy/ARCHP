# ADR-007: Interrupts, INT and RTI — edge-latched request, injected micro-ops, packed context word

- **Status:** Accepted
- **Date:** 2026-11-04
- **Session:** S001
- **Related:** REQ-G5, REQ-G6, REQ-I14, T-008

## Context
On INTR.IN the processor must finish the instructions already in the pipeline, push the address of the next instruction, preserve the flags and jump to M[1]. INT pushes PC+1 and jumps to M[index+2]. RTI restores PC and flags. The stack slot per the brief is one word. The brief stresses corner cases such as branches.

## Decision
- **Sampling:** INTR.IN is rising-edge detected (a 1-cycle pulse is enough; holding it high does not re-trigger) and latched in `int_pending`.
- **Context word:** one word `{C N Z at [31:29], zeros, return PC at [11:0]}`; RTI restores both. CALL pushes a plain return address.
- **INT n** is decoded into two micro-ops:
  1. push the context with return PC = PC+1 (SP−1);
  2. a vector read of address `2+n` whose data loads PC in WB.
  Decode then waits for the PC load.
- **Hardware interrupt:** when `int_pending` is set and decode holds a **valid** instruction I (not inside a micro-op sequence, not waiting, not halted), I is replaced by two micro-ops:
  1. push the context with return PC = address of I;
  2. a vector read of M[1].
  All older instructions complete normally. I runs after RTI.
- **Corner cases:**
  - `int_pending` is cleared only when the push micro-op reaches EX2, which is never flushed.
  - If I was on a wrong path (an older branch mispredicts in EX2), the micro-ops are flushed with it and the interrupt is re-injected on the correct path, so the saved PC is always architecturally correct.
  - Interrupts are not taken after HLT.

## Alternatives considered
| Option | Why not |
|---|---|
| Shadow flag register | Not re-entrant |
| Push flags as a second word | Doesn't match `SP−=1` |
| Drain the whole pipeline, then a hardware FSM | More states and a second path to the memory port; injection reuses the existing push/read datapath |
| Level-sensitive INTR | Must be dropped before RTI or it fires again |

## Consequences
- 5-cycle interrupt entry penalty.
- The testbench logs the number of retired instructions at each interrupt so the golden model can replay the interrupt at the same architectural point (ADR-013).
