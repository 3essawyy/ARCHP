# PLAN-009: ModelSim do-files and demo guide (for T-009)

- **Task:** [T-009](../tasks/T-009-modelsim-demo.md)
- **Status:** Executed
- **Date:** 2026-11-04

## Approach
Reuse `tb_processor` (same as CI); write the three do-files and make everything that can be checked without ModelSim a pytest test.

## Steps
1. `compile.do` (explicit dependency order), `wave.do` (required signals only), `run.do` (program stem, optional `dynamic`).
2. Assembler writes `.in`/`.intr`; `sim.run_rtl` reuses the same text.
3. `tests/test_modelsim.py`: file coverage, order (GHDL plain `-a` in listed order), wave signals, run generics.
4. SG-004.

## Files to create/change
| Path | Change |
|---|---|
| `sim/modelsim/{compile,run,wave}.do` | New |
| `src/archp/assembler.py` (`stimulus_texts`), `src/archp/sim.py` | Changed |
| `tests/test_modelsim.py`, `docs/SystemGuides/SG-004-modelsim-demo.md` | New |

## Tests to add
| Test | Proves |
|---|---|
| `test_compile_do_order_is_valid` | ModelSim will compile without order errors (mutation-checked) |
| `test_wave_do_signals_exist` | The demo wave shows exactly the required signals |

## Risks / open questions
| Item | Mitigation / decision |
|---|---|
| ModelSim not available in CI | The team runs SG-004 once (TC-213) |

## Deviations (filled after execution)
None.
