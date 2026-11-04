# T-008: Interrupts, INT/RTI, reset boot, HLT

- **Status:** Todo
- **Phase:** P2
- **Target:** W+3
- **Modules:** interrupts, decode, fetch
- **Requirements:** REQ-G5…G7, REQ-I1, REQ-I14
- **Depends on:** T-007
- **Plan:** PLAN-008 (written when the task starts)
- **TCs:** TC-207, TC-208
- **ADRs:** ADR-007, ADR-010
- **Session:** —
- **Branch / PR:** `feat/T-008-interrupts-reset-hlt` / PR —

## Goal
Complete ISA: interrupts with corner cases, software INT, RTI, reset vector, HLT.

## Scope
- In: INTR edge latch, injection, micro-ops, context word, boot sequence, halted state; interrupt programs with pulses on branch/stall/load/CALL/RET corners.
- Out: Bonus predictor.

## Acceptance criteria
- [ ] Interrupt sweep (pulse at every cycle of a branchy program) passes RTL == golden
- [ ] Reset vector and HLT programs pass

## Definition of Done
- [ ] Code + tests passing (CI green)
- [ ] Module LLD updated
- [ ] Explain it section complete
- [ ] TCs updated
- [ ] ADR (if decision made)
- [ ] SystemGuides (if setup/usage changed)
- [ ] Session log
- [ ] PR squash-merged

## Notes / log

## Explain it (code-defense prep)
- **What changed:**
- **Why this design:**
- **How it works (walkthrough with file/function references):**
- **Likely examiner questions + answers:**
