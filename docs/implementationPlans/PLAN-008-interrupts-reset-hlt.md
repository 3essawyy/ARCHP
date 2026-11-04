# PLAN-008: Interrupts, INT/RTI, reset boot, HLT (for T-008)

- **Task:** [T-008](../tasks/T-008-interrupts-reset-hlt.md)
- **Status:** Executed
- **Date:** 2026-11-04

## Approach
ADR-007: inject micro-ops in decode and reuse push + the RET-style PC load. The request latch is acknowledged in EX2. Reset boot and HLT already exist from T-006/T-007; this task adds the INTR-after-HLT test. Verification: a sweep over every cycle, plus random programs with interrupts, plus mutations.

## Steps
1. Core: INTR edge detector + `int_pending` (ack = hwint micro-op in EX2).
2. Decode: `inject`, `hw_phase`, INT phase handling, vector immediates, `ret_pc` override, `start_wait` for vector micro-ops.
3. `programs/interrupt.asm` (ISR preserves state, counts interrupts).
4. `tests/test_interrupts.py`: baseline, sweep 1…124, held high, nested, merge, after HLT, 30 random programs.
5. Mutations; timing of INT+RTI.

## Files to create/change
| Path | Change |
|---|---|
| `rtl/decode/decode_stage.vhd`, `rtl/core/processor_core.vhd` | Changed |
| `programs/interrupt.asm`, `tests/test_interrupts.py` | New |
| `tests/test_golden.py`, `tests/test_programs.py`, `tests/test_timing.py` | Changed |

## Tests to add
| Test | Proves |
|---|---|
| `test_single_pulse_sweep[1..124]` | Precise interrupts at every pipeline situation |
| `test_held_high_is_one_interrupt`, `test_interrupt_after_hlt_is_ignored` | Edge sensitivity, ADR-010 |
| `test_fuzz_with_interrupts[0..29]` | Random code + INT + INTR |

## Risks / open questions
| Item | Mitigation / decision |
|---|---|
| Two edges in quick succession | Measured: merge if < 3 cycles apart; documented in ADR-007 |

## Deviations (filled after execution)
- Nested-interrupt test spacing changed from 2 to 3 cycles after measuring (see the T-008 notes).
