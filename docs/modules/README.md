# Modules (low-level design)

One folder per module; `README.md` inside is its LLD (template: [_TEMPLATE.md](_TEMPLATE.md)). The LLD describes the module as built on `main`; update it in the same PR as the code (Definition of Done).

| Module | Responsibility | Owner | Status | Tasks |
|---|---|---|---|---|
| [fetch](fetch/README.md) | PC, next-address mux, fetch/memory arbitration, IF/ID valid | TBD | Planned | T-006, T-007, T-010 |
| [decode](decode/README.md) | Control unit, micro-op sequencer, redirects, HLT | TBD | Planned | T-006, T-007, T-008 |
| [register-file](register-file/README.md) | 8x32 registers, 2 read / 1 write port, WB bypass | TBD | Planned | T-005 |
| [pipeline](pipeline/README.md) | ID/EX1, EX1/EX2, EX2/MEM, MEM/WB registers | TBD | Planned | T-006 |
| [ex1](ex1/README.md) | ALU, immediate select, IN sample, CCR | TBD | Planned | T-005, T-006 |
| [ex2](ex2/README.md) | Branch resolution/flush, SP, memory address + store data | TBD | Planned | T-006, T-007 |
| [mem-wb](mem-wb/README.md) | Unified M10K memory, MEM port ownership, write-back, OUT.PORT | TBD | Planned | T-005, T-006, T-008 |
| [hazards](hazards/README.md) | Forwarding unit + load-use hazard detection | TBD | Planned | T-006 |
| [interrupts](interrupts/README.md) | INTR edge latch, injection, INT/RTI, reset boot | TBD | Planned | T-008 |
| [predictor](predictor/README.md) | Bonus: BTB + 2-bit counters in fetch | TBD | Planned | T-010 |
| [assembler](assembler/README.md) | ISA tables + TA-format assembler (.mem/.mif) | TBD | Planned | T-003 |
| [golden-model](golden-model/README.md) | Instruction-level ISA reference model | TBD | Planned | T-004 |
| [sim](sim/README.md) | Testbenches, GHDL runner, compare, ModelSim, Quartus, CI | TBD | Planned | T-002, T-006, T-009, T-011 |

> **Owners:** assign one team member per group at kickoff and replace `TBD`. Suggested balanced grouping (each member owns hardware they can defend end to end):
> 1. **Front end:** fetch + predictor (bonus) + mem-wb
> 2. **Decode and control:** decode + register-file + interrupts
> 3. **Execute and hazards:** ex1 + ex2 + hazards + pipeline
> 4. **Tools and verification:** assembler + golden-model + sim (ModelSim/Quartus demo owner)

## Dependency direction
`processor_top → processor_core → {fetch, decode, pipeline regs, ex1, ex2, memory}`; `decode → {control_unit, register_file}`; `ex1 → {alu, forwarding_unit, ccr}`. Everything uses `archp_pkg`; nothing imports the core. On the Python side: `cli → {assembler, golden, ghdl, compare}`, and `golden`/`assembler` depend only on `isa`.
