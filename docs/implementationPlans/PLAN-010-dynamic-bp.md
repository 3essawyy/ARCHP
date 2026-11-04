# PLAN-010: Bonus 2-bit dynamic predictor with BTB in fetch (for T-010)

- **Task:** [T-010](../tasks/T-010-dynamic-bp.md)
- **Status:** Executed
- **Date:** 2026-11-04

## Approach
ADR-012: BTB + 2-bit counters looked up with the fetch address; EX2 already resolves with `taken xor pred` (T-007). Everything behind `G_DYNAMIC_BP` using `if … generate`, so the static (ranked) build is unchanged.

## Steps
1. `btb.vhd`; fetch generate blocks (`next_pc`, `npc_r`, `pred_r`).
2. Decode `pred` on conditional jumps, stale-hit fix; EX2 `bp_valid/bp_taken`.
3. Run every test family in both modes; `loop.asm` speed-up; loop fuzzing; `smc_btb.asm`.
4. Mutations.

## Files to create/change
| Path | Change |
|---|---|
| `rtl/fetch/btb.vhd` | New |
| `rtl/fetch/fetch_unit.vhd`, `rtl/decode/decode_stage.vhd`, `rtl/execute/ex2_stage.vhd`, `rtl/core/processor_core.vhd`, `sim/modelsim/compile.do` | Changed |
| `programs/{loop,smc_btb}.asm`, `src/archp/fuzz.py` (loops), tests | New / changed |

## Tests to add
| Test | Proves |
|---|---|
| All program/fuzz/interrupt tests x {static, dynamic} | Both builds correct (REQ-E7) |
| `test_dynamic_predictor_speeds_up_loops` | Predictor actually predicts (58 cycles saved) |
| `test_fuzz_loops[*]` | Repeated branches, predict-taken and mispredict-exit paths |

## Risks / open questions
| Item | Mitigation / decision |
|---|---|
| The static build changes by accident | Cycle counts unchanged; T-011 synthesis compares both builds |

## Deviations (filled after execution)
- Added loop fuzzing and `smc_btb.asm` after finding coverage gaps (see the T-010 notes).
