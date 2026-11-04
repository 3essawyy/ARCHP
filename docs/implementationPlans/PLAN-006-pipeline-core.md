# PLAN-006: Pipeline core + RTL test harness (for T-006)

- **Task:** [T-006](../tasks/T-006-pipeline-core.md)
- **Status:** Executed
- **Date:** 2026-11-04

## Approach
Build the core per HLD §4–§6 for every non-control instruction. Branch/CALL/RET sequencing comes in T-007 and interrupts in T-008; the control-unit table already has their rows. Verify with the RTL-vs-golden harness (ADR-013) on hand-written programs plus random programs, then prove the tests are sensitive by mutating the hazard logic.

## Steps
1. `control_unit` (full table), `decode_stage` (HDU, replay, SWAP sequencer, HLT), `fetch_unit` (priority mux, boot).
2. `forwarding_unit`, `ex1_stage`, `ex2_stage` (SP/address/data), 4 pipeline-register entities, `processor_core`.
3. `tb_processor` (program load, IN feed on `in_rd`, INTR pulses, shadow memory, dump).
4. `archp.sim` (build/run/parse/compare), `archp.fuzz`, CLI `sim`/`check`.
5. Programs `hazards_data`, `hazards_structural`; tests `test_programs.py`, `test_timing.py`.
6. Mutation runs; penalty measurements vs HLD §6.

## Files to create/change
| Path | Change |
|---|---|
| `rtl/decode/{control_unit,decode_stage}.vhd`, `rtl/fetch/fetch_unit.vhd` | New |
| `rtl/execute/{forwarding_unit,ex1_stage,ex2_stage}.vhd`, `rtl/pipeline/*.vhd`, `rtl/core/processor_core.vhd` | New |
| `tb/tb_processor.vhd` | New |
| `src/archp/{sim,fuzz}.py`, `src/archp/ghdl.py` (make + elab-run), `src/archp/cli.py` | New / changed |
| `programs/hazards_{data,structural}.asm`, `tests/test_{programs,timing}.py` | New |

## Tests to add
| Test | Proves |
|---|---|
| `test_program_static[*]` | TC-201…205 programs: RTL == golden + expectations |
| `test_fuzz_straight_line[0..39]` | Random hazard-dense programs: RTL == golden |
| `test_penalty[*]` | Measured stall penalties equal HLD §6 |

## Risks / open questions
| Item | Mitigation / decision |
|---|---|
| Tests pass because they test nothing | Six mutations of the hazard logic; each makes 14–44 tests fail |

## Deviations (filled after execution)
- `archp.ghdl.analyse` gained `top=` (import + make). `run` switched to `--elab-run` (see the T-006 notes).
