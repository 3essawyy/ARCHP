# Decisions (ADRs)

Never delete or rewrite an accepted ADR. To change a decision, add a new ADR and mark the old one `Superseded by ADR-NNN`. Template: [_TEMPLATE.md](_TEMPLATE.md).

| ID | Title | Status | Date |
|---|---|---|---|
| [ADR-001](ADR-001-team-workflow-and-docs.md) | Team workflow and documentation structure | Accepted | 2026-11-04 |
| [ADR-002](ADR-002-toolchain.md) | Toolchain: VHDL-93, GHDL in CI, ModelSim/Quartus locally, Python (uv) | Accepted | 2026-11-04 |
| [ADR-003](ADR-003-instruction-format.md) | One 32-bit word per instruction, fixed register fields | Accepted | 2026-11-04 |
| [ADR-004](ADR-004-unified-memory.md) | Single-port unified M10K memory; MEM priority; RAM output as IR; replay | Accepted | 2026-11-04 |
| [ADR-005](ADR-005-immediate-extension.md) | LDM zero-extends; IADD and offsets sign-extend | Accepted | 2026-11-04 |
| [ADR-006](ADR-006-flag-semantics.md) | Flag semantics (borrow, shifts, jump clears flag) and timing | Accepted | 2026-11-04 |
| [ADR-007](ADR-007-interrupts.md) | Interrupts, INT, RTI: edge latch, injected micro-ops, packed context | Accepted | 2026-11-04 |
| [ADR-008](ADR-008-swap-micro-ops.md) | SWAP as two micro-ops, one write port | Accepted | 2026-11-04 |
| [ADR-009](ADR-009-pc-sp-width.md) | 12-bit physical PC/SP, 32-bit view | Accepted | 2026-11-04 |
| [ADR-010](ADR-010-hlt.md) | HLT stops fetch and drains; no clock gating | Accepted | 2026-11-04 |
| [ADR-011](ADR-011-static-branch-prediction.md) | Static not-taken; JMP/CALL redirect in decode | Accepted | 2026-11-04 |
| [ADR-012](ADR-012-dynamic-branch-prediction.md) | Bonus: 2-bit predictor + BTB in fetch behind `G_DYNAMIC_BP` | Accepted | 2026-11-04 |
| [ADR-013](ADR-013-verification-strategy.md) | Golden model vs RTL on every program, both builds | Accepted | 2026-11-04 |
| [ADR-014](ADR-014-stage-mapping.md) | Effective address in EX1 adder; EX2 forms final address | Accepted | 2026-11-04 |
| [ADR-015](ADR-015-register-read-in-ex1.md) | Register file read in EX1; no ID/EX1 operands, no RF bypass | Accepted | 2026-11-04 |

## Open decisions (to become ADRs)
| Topic | Decide in |
|---|---|
| Report rendering (Markdown → PDF tool) and schematic generation | T-012 |
| Further area optimisations after the first Flow Summary | T-011 |
