# Tasks — source of truth for status

Update this table in the same PR that changes a task's status. Template: [_TEMPLATE.md](_TEMPLATE.md). Weeks are **relative** (W+0 = week of 2026-11-04).

Milestones: **M1 = Phase 1 submission (Week 11)** · **M2 = Phase 2 demo (Week 13)**

The brief's advice "integrate incrementally" shapes the order: leaf blocks (T-005) → core without control flow (T-006) → control flow (T-007) → interrupts (T-008). Each step is verified against the golden model before the next starts.

## Foundation and Phase 1

| ID | Title | Modules | Depends on | Target | Status |
|---|---|---|---|---|---|
| [T-001](T-001-docs-scaffold.md) | Docs scaffold, requirements, HLD, ADRs, task breakdown | docs | — | W+0 | Done |
| [T-002](T-002-repo-skeleton-ci.md) | Repo skeleton, tooling and CI (uv, ruff, mypy, pytest, GHDL) | sim | T-001 | W+0 | Done |
| [T-003](T-003-isa-assembler.md) | ISA definition and assembler | assembler | T-002 | W+1 | Done |
| [T-012](T-012-phase1-pack.md) | Phase 1 submission pack: schematic and design report | docs | T-008 | before W11 | Todo |

## Phase 2 and bonus

| ID | Title | Modules | Depends on | Target | Status |
|---|---|---|---|---|---|
| [T-004](T-004-golden-model.md) | Golden ISA model and base test programs | golden-model | T-003 | W+1 | Done |
| [T-005](T-005-rtl-blocks.md) | RTL building blocks: package, memory, register file, ALU, CCR | memory, register-file, ex1 | T-002 | W+2 | Done |
| [T-006](T-006-pipeline-core.md) | Pipeline core: stages, pipeline registers, forwarding, load-use, structural hazards, SWAP + RTL test harness | fetch, decode, pipeline, ex1, ex2, mem-wb, hazards, sim | T-004, T-005 | W+2 | Done |
| [T-007](T-007-control-flow.md) | Control flow: static prediction, flush, JMP/CALL/RET | fetch, decode, ex2 | T-006 | W+3 | Done |
| [T-008](T-008-interrupts-reset-hlt.md) | Interrupts, INT/RTI, reset boot, HLT | interrupts, decode, fetch | T-007 | W+3 | Todo |
| [T-009](T-009-modelsim-demo.md) | ModelSim do-files, waveform and demo guide | sim | T-008 | W+4 | Todo |
| [T-010](T-010-dynamic-bp.md) | Bonus: 2-bit dynamic branch predictor with BTB in fetch | predictor, fetch, ex2 | T-008 | W+4 | Todo |
| [T-011](T-011-quartus-area.md) | Quartus project, synthesis checks and area tuning | sim, all RTL | T-008 | W+5 | Todo |
| [T-013](T-013-phase2-pack.md) | Phase 2 submission pack and final verification | docs | all | before W13 | Todo |
