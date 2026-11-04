# T-006: Pipeline core: stages, pipeline registers, forwarding, load-use, structural hazards, SWAP + RTL test harness

- **Status:** Todo
- **Phase:** P2
- **Target:** W+2
- **Modules:** fetch, decode, pipeline, ex1, ex2, mem-wb, hazards, sim
- **Requirements:** REQ-G1, REQ-P2-1, REQ-P2-2, REQ-E5
- **Depends on:** T-004, T-005
- **Plan:** PLAN-006 (written when the task starts)
- **TCs:** TC-201…TC-205
- **ADRs:** ADR-004, ADR-008, ADR-013, ADR-014
- **Session:** —
- **Branch / PR:** `feat/T-006-pipeline-core` / PR —

## Goal
A working 6-stage core for all non-control instructions, verified against the golden model.

## Scope
- In: fetch unit, decode stage + control unit, pipeline registers, EX1/EX2, MEM/WB, forwarding unit, HDU, memory arbitration, SWAP micro-ops, `processor_core`, `tb_processor`, `archp.ghdl`/`archp.compare`, CLI `archp sim/check`.
- Out: Branches, interrupts (T-007, T-008).

## Acceptance criteria
- [ ] One/two-operand and memory programs: RTL == golden
- [ ] Forwarding at distances 1–4 and load-use 1–3 covered
- [ ] Memory-conflict and SWAP programs pass

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
