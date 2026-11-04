# T-011: Quartus project, synthesis checks and area tuning

- **Status:** Todo
- **Phase:** P2
- **Target:** W+5
- **Modules:** sim, all RTL
- **Requirements:** REQ-P2-6, REQ-P2-7, REQ-E3, REQ-E4, REQ-E7
- **Depends on:** T-008
- **Plan:** PLAN-011 (written when the task starts)
- **TCs:** TC-211, TC-212
- **ADRs:** ADR-002
- **Session:** —
- **Branch / PR:** `feat/T-011-quartus-area` / PR —

## Goal
A Quartus 16.1 project that compiles with default settings into M10K memory, plus automated latch/synthesis checks.

## Scope
- In: `quartus/archp.qpf/.qsf`, `processor_top`, `ghdl --synth` check in CI, MIF generation, SG-005 Quartus guide, area notes.
- Out: —

## Acceptance criteria
- [ ] `ghdl --synth` of the top passes with no latches
- [ ] Team compiles in Quartus: block memory bits = 131072, Flow Summary recorded

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
