# T-003: ISA definition and assembler

- **Status:** Todo
- **Phase:** P1
- **Target:** W+1
- **Modules:** assembler
- **Requirements:** REQ-P1-1, REQ-P2-3, REQ-E1
- **Depends on:** T-002
- **Plan:** PLAN-003 (written when the task starts)
- **TCs:** TC-103, TC-104
- **ADRs:** ADR-003, ADR-005
- **Session:** —
- **Branch / PR:** `feat/T-003-isa-assembler` / PR —

## Goal
One Python source of truth for the encoding (`archp.isa`) and an assembler that reads TA-format programs and writes `.mem` (GHDL/ModelSim) and `.mif` (Quartus).

## Scope
- In: `isa.py` tables, `assembler.py` (labels, `.ORG`, data words, hex/decimal/negative numbers, `#` and `;` comments, case-insensitive), `#!` directives, CLI `archp asm`, SG-003.
- Out: Disassembler beyond what tests need.

## Acceptance criteria
- [ ] Every instruction encodes per HLD §3.2 (table-driven test)
- [ ] TA-format sample programs assemble
- [ ] Clear errors with line numbers for bad input
- [ ] `.mem` is 4096 lines of 8 hex digits; `.mif` valid

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
