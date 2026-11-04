# ADR-013: Verification — golden ISA model vs RTL on every program, both predictor builds

- **Status:** Accepted
- **Date:** 2026-11-04
- **Session:** S001
- **Related:** REQ-P2-2, REQ-E1, REQ-E6, T-004, T-006

## Context
A non-working processor nullifies the grade, and ModelSim isn't available in CI. We need strong, automatic evidence on every PR.

## Decision
- **`archp.golden`:** an instruction-level Python model of the ISA exactly as specified by ADR-003…011. It is the executable specification and has its own unit tests derived from the brief.
- **Programs** (`programs/*.asm`) embed their stimuli and expectations in comments:
  - `#! in: 30 50 …` — IN.PORT values;
  - `#! intr: 40 95` — INTR.IN pulse cycles;
  - `#! expect: R1=30 SP=FFE …` — checked against the golden model.
- **RTL run (GHDL):** `tb_processor` loads the `.mem` file, feeds IN.PORT from the list (advanced on the core's `in_rd` strobe), pulses INTR.IN and runs until halted and drained. It dumps R0–R7, SP, flags, the OUT log, the interrupt log (retired-instruction count at each interrupt), the retired count and the full memory.
- **Compare:** the golden model replays the same inputs and takes each hardware interrupt after the same number of retired instructions as the RTL. Everything in the dump must match exactly. This runs for `G_DYNAMIC_BP = false` and `true`.
- **Unit testbenches** (ALU, register file, memory) are self-checking VHDL run by pytest.

## Alternatives considered
| Option | Why not |
|---|---|
| Hand-written expected values only | Weak coverage; misses memory corruption |
| Compare cycle-by-cycle traces | Couples the model to the micro-architecture |

## Consequences
Interrupt *timing* (which instruction gets interrupted) comes from the RTL. Its legality is checked: it must be an instruction boundary on the correct path. Architectural results are checked by the model.
