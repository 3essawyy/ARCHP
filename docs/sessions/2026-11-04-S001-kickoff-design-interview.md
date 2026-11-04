# Session S001 — 2026-11-04 — Kickoff: design interview + docs scaffold

- **Tasks touched:** T-001
- **Branches / PRs:** `main` bootstrap; `docs/T-001-docs-scaffold`

## Done
- Read the Fall 2026 brief and the previous-term reference repo (jouu556/six-stage-pipeline-processor) as a base only.
- Grill-me interview (5 rounds). Every answer is recorded as an ADR:

| Area | Decision | ADR |
|---|---|---|
| Instruction format | One 32-bit word per instruction | [ADR-003](../decisions/ADR-003-instruction-format.md) |
| Memory | Single-port M10K, MEM priority, fetch stall | [ADR-004](../decisions/ADR-004-unified-memory.md) |
| Git | Per-task PRs, squash to `main` | [ADR-001](../decisions/ADR-001-team-workflow-and-docs.md) |
| Verification | GHDL CI + Python golden model; team runs ModelSim/Quartus | [ADR-002](../decisions/ADR-002-toolchain.md), [ADR-013](../decisions/ADR-013-verification-strategy.md) |
| Immediates | LDM zero-extends; IADD sign-extends | [ADR-005](../decisions/ADR-005-immediate-extension.md) |
| Carry | SUB/CMP C = borrow | [ADR-006](../decisions/ADR-006-flag-semantics.md) |
| Flag save | Packed into the pushed word | [ADR-007](../decisions/ADR-007-interrupts.md) |
| Conditional jumps | Clear the tested flag only if taken | [ADR-006](../decisions/ADR-006-flag-semantics.md) |
| Shifts | Literal: SHL updates C, SHR doesn't | [ADR-006](../decisions/ADR-006-flag-semantics.md) |
| SWAP | One write port, two micro-ops | [ADR-008](../decisions/ADR-008-swap-micro-ops.md) |
| PC/SP | 12-bit physical, 32-bit view | [ADR-009](../decisions/ADR-009-pc-sp-width.md) |
| HLT | Stop fetch, drain older instructions | [ADR-010](../decisions/ADR-010-hlt.md) |
| Static prediction | Not-taken; JMP/CALL in decode | [ADR-011](../decisions/ADR-011-static-branch-prediction.md) |
| Bonus | Yes, behind a generic | [ADR-012](../decisions/ADR-012-dynamic-branch-prediction.md) |
| INTR.IN | Rising edge, latched | [ADR-007](../decisions/ADR-007-interrupts.md) |
| Phase 1 docs | draw.io + Markdown → PDF | T-012 |
| Owners | TBD with a suggested 4-way grouping | [modules](../modules/README.md) |
| Python stack | Same as GATP (uv, ruff, mypy, pytest, poe) | [ADR-002](../decisions/ADR-002-toolchain.md) |
| Docs | Mirror GATP's structure in ARCHP only | [ADR-001](../decisions/ADR-001-team-workflow-and-docs.md) |

- Additional design decisions taken by Claude: [ADR-014](../decisions/ADR-014-stage-mapping.md) (effective address in the EX1 adder); replay instead of an IR hold register, plus interrupt injection rules (ADR-004/007).
- Docs scaffold: CLAUDE.md, HLD, REQ, ADR-001…014, T-001…T-013, module stubs, TCs, indexes.
- User instruction mid-session: **always test the work and use the results as feedback**. This is now in ADR-001 and the Definition of Done.

## Decisions (with ADR links)
ADR-001…ADR-014 (table above).

## Open items / blockers
- Module owners to be named by the team.
- ModelSim and Quartus runs need a team member's machine (TC-212, TC-213).

## Next steps (in order)
1. T-002 repo skeleton + CI (GHDL in Actions).
2. T-003 assembler, T-004 golden model.
3. T-005 → T-008 RTL, incrementally, each verified against the golden model.

## Notes for next session
- GHDL 4.1 (mcode) is installed from Ubuntu noble apt in the container (`apt-get install ghdl`).
