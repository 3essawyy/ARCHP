# T-005: RTL building blocks: package, memory, register file, ALU, CCR

- **Status:** Todo
- **Phase:** P2
- **Target:** W+2
- **Modules:** memory, register-file, ex1
- **Requirements:** REQ-P2-1, REQ-P2-7
- **Depends on:** T-002
- **Plan:** PLAN-005 (written when the task starts)
- **TCs:** TC-106
- **ADRs:** ADR-004, ADR-006
- **Session:** —
- **Branch / PR:** `feat/T-005-rtl-blocks` / PR —

## Goal
Self-checked leaf components, integrated incrementally as the brief advises.

## Scope
- In: `archp_pkg`, `unified_memory` (M10K style, file init), `register_file`, `alu`, `ccr`; self-checking unit testbenches run by pytest via GHDL.
- Out: Pipeline.

## Acceptance criteria
- [ ] Unit TBs pass in GHDL
- [ ] ALU flag results match the golden model's ALU function for a sweep of vectors

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
