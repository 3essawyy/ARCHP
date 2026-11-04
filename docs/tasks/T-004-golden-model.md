# T-004: Golden ISA model and base test programs

- **Status:** Todo
- **Phase:** P2
- **Target:** W+1
- **Modules:** golden-model
- **Requirements:** REQ-I*, REQ-G6, REQ-G7
- **Depends on:** T-003
- **Plan:** PLAN-004 (written when the task starts)
- **TCs:** TC-105
- **ADRs:** ADR-005…ADR-010, ADR-013
- **Session:** —
- **Branch / PR:** `feat/T-004-golden-model` / PR —

## Goal
An instruction-level executable specification used to check the RTL.

## Scope
- In: `golden.py` (state, step, run, interrupts at retired counts, IN queue, OUT log), `#! expect` checks, CLI `archp golden`, base programs per instruction group.
- Out: Cycle accuracy.

## Acceptance criteria
- [ ] Unit tests for every instruction and flag rule in ADR-005/006
- [ ] Programs' `#! expect` lines pass on the model

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
