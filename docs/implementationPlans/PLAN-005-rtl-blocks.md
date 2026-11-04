# PLAN-005: RTL building blocks (for T-005)

- **Task:** [T-005](../tasks/T-005-rtl-blocks.md)
- **Status:** Executed
- **Date:** 2026-11-04

## Approach
Leaf blocks first, as the brief advises ("integrate incrementally"). Each block has a self-checking bench. The ALU is checked against the golden `alu()` on ~4,500 generated vectors, so the RTL and the model share one definition of every flag rule.

## Steps
1. `archp_pkg` with every record the core will need (control word, 4 pipeline registers).
2. `alu`, `ccr`, `register_file`, `unified_memory`.
3. `tb_util_pkg` (hex helpers), `tb_alu` (vector file), `tb_register_file`, `tb_memory`, `tb_ccr`.
4. `tests/test_rtl_units.py`: generate vectors, run benches. Also a guard that the RTL carry constant equals the golden one, and a check that `rtl/` contains no VHDL-2008 constructs.
5. Mutation-check each bench; `ghdl --synth` each block.

## Files to create/change
| Path | Change |
|---|---|
| `rtl/pkg/archp_pkg.vhd`, `rtl/execute/{alu,ccr}.vhd`, `rtl/decode/register_file.vhd`, `rtl/memory/unified_memory.vhd` | New |
| `tb/tb_util_pkg.vhd`, `tb/unit/tb_{alu,register_file,memory,ccr}.vhd` | New |
| `tests/test_rtl_units.py` | New |

## Tests to add
| Test | Proves |
|---|---|
| `test_alu_matches_golden` | RTL ALU == golden ALU (result, Z, N, C, write enables) on edges + 300 random pairs |
| `test_register_file` | reset, both ports, bypass, no false bypass |
| `test_memory` | file init incl. `@addr`, 1-cycle latency, write/read-back |
| `test_ccr` | priorities: younger EX1 beats EX2 clear; RTI restore |
| `test_rtl_carry_switch_matches_golden` | The one-constant carry convention stays in sync |

## Risks / open questions
| Item | Mitigation / decision |
|---|---|
| Quartus might not accept textio in the init function | Wrapped in `synthesis translate_off`; confirmed in Quartus in TC-212 |

## Deviations (filled after execution)
- Added the mutation checks and synth check (user instruction: test and use the feedback).
