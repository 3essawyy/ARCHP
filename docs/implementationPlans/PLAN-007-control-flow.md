# PLAN-007: Control flow (for T-007)

- **Task:** [T-007](../tasks/T-007-control-flow.md)
- **Status:** Executed
- **Date:** 2026-11-04

## Approach
Per ADR-011:
- branch unit in EX2 with `redirect = taken xor pred` (written for the bonus too);
- decode redirect for JMP/CALL;
- `wait` for RET/RTI;
- a flush that undoes all speculative decode state.

## Steps
1. `ex2_stage`: `cond`, `taken`, `redirect`, `target`, `clr` outputs.
2. `decode_stage`: `redirect/target`, `wait_r`, `pcl_valid` input, flush clears phase/wait/halted.
3. `processor_core`: wire flush = EX2 redirect, decode redirect into fetch.
4. Program `control_corners.asm`; fuzz with branches + calls; timing cases.
5. Mutation runs.

## Files to create/change
| Path | Change |
|---|---|
| `rtl/execute/ex2_stage.vhd`, `rtl/decode/decode_stage.vhd`, `rtl/core/processor_core.vhd` | Changed |
| `programs/control_corners.asm`, `tests/test_programs.py`, `tests/test_timing.py` | New / changed |

## Tests to add
| Test | Proves |
|---|---|
| `test_program_static[branch,call_ret,control_corners]` | TC-206 |
| `test_fuzz_control_flow[0..39]` | Random forward branches + CALL/RET: RTL == golden |
| `test_penalty[jz-taken,jmp,call-ret]` | 2 / 0 / 4 cycles |

## Risks / open questions
| Item | Mitigation / decision |
|---|---|
| Speculative decode state leaking from the wrong path | Flush clears phase/wait/halted; tested |

## Deviations (filled after execution)
None.
