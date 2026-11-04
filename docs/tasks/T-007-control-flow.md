# T-007: Control flow: static prediction, flush, JMP/CALL/RET

- **Status:** Todo
- **Phase:** P2
- **Target:** W+3
- **Modules:** fetch, decode, ex2
- **Requirements:** REQ-I12, REQ-I13, REQ-P1-4, REQ-E5
- **Depends on:** T-006
- **Plan:** PLAN-007 (written when the task starts)
- **TCs:** TC-206
- **ADRs:** ADR-011
- **Session:** —
- **Branch / PR:** `feat/T-007-control-flow` / PR —

## Goal
Correct branches with not-taken static prediction and zero-penalty JMP/CALL.

## Scope
- In: Branch unit, flush, flag clear, decode redirects, RET wait/pc-load.
- Out: INT/RTI.

## Acceptance criteria
- [ ] Branch programs (taken/not taken, flag clear, nested CALL/RET, back-to-back branches) pass RTL == golden

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
