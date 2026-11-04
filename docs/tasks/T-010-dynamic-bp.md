# T-010: Bonus: 2-bit dynamic branch predictor with BTB in fetch

- **Status:** Todo
- **Phase:** Bonus
- **Target:** W+4
- **Modules:** predictor, fetch, ex2
- **Requirements:** REQ-E5 (bonus), REQ-E7
- **Depends on:** T-008
- **Plan:** PLAN-010 (written when the task starts)
- **TCs:** TC-210
- **ADRs:** ADR-012
- **Session:** —
- **Branch / PR:** `feat/T-010-dynamic-bp` / PR —

## Goal
Bonus marks without risking the ranked static build.

## Scope
- In: `btb.vhd`, `G_DYNAMIC_BP` generic, EX2 mispredict both directions, CI matrix both builds.
- Out: —

## Acceptance criteria
- [ ] All programs pass with G_DYNAMIC_BP = true and false
- [ ] Loop program shows fewer cycles with the predictor

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
