# Module: interrupts

- **Owner:** TBD
- **Status:** Implemented (T-008)
- **Code:** `decode_stage.vhd`, `processor_core.vhd`
- **Tasks:** T-008
- **ADRs:** ADR-007

## Responsibility
INTR.IN edge detection and pending latch, injection rules, interrupt/INT micro-ops, context word, RTI restore, reset boot sequence.

## Interfaces
| Direction | Interface | Contract |
|---|---|---|
| Provides | `int_pending` latch (core) | Set on the INTR rising edge; cleared when the hwint push micro-op is in EX2 |
| Provides | Injection + micro-ops (decode) | push `{CNZ, id_pc}` → vector read of M[1] → `wait` |
| Provides | INT n micro-ops (decode) | push `{CNZ, PC+1}` → vector read of `2+n` → `wait` |
| Provides | RTI (WB) | PC ← q(11:0), CCR ← q(31:29) |
| Provides | Boot (fetch) | reset → read M[0] → PC |

## Data
Context word: `[31]=C [30]=N [29]=Z [11:0]=return PC`, other bits 0 (ADR-007).

## Internal design
- **`inject`** `= valid_in and int_pending and not phase and not hw_phase`.
- **Control unit inputs:** `cu_hw = hw_phase or inject`, `cu_phase = phase or hw_phase`.
- **Vector immediates:** `x"0001"` (hardware interrupt) and `"0…01" & instr(0)` (INT); the ALU passes them through as the memory address.
- **Flush** clears `hw_phase`; `int_pending` survives until EX2 acknowledges it.
- See the T-008 Explain it section for the full sequence.

## Validation and failure modes
| Failure | Detection | Behavior |
|---|---|---|
| Injected micro-ops flushed (wrong path) | EX2 redirect | `int_pending` still set → re-injected on the correct path |
| Two edges < 3 cycles apart | — | Merged into one interrupt (documented, ADR-007) |
| INTR after HLT | `halted` → decode invalid | Ignored until reset |

## Config
| Key | Default | Meaning |
|---|---|---|

## Tests
`tests/test_interrupts.py` (TC-207), `programs/int_sw.asm`, `programs/interrupt.asm`, `tests/test_timing.py::test_int_entry_plus_rti_penalty`.

## Known limitations
