# PLAN-004: Golden ISA model and base test programs (for T-004)

- **Task:** [T-004](../tasks/T-004-golden-model.md)
- **Status:** Executed
- **Date:** 2026-11-04

## Approach
A small, direct interpreter of the ISA (one `if/elif` per opcode) that is easy to read during the defense. Interrupt timing is an input (retired counts), not modelled. Base programs per instruction group carry hand-computed expectations, which cross-check the model itself.

## Steps
1. `alu()` reference with explicit Z/N/C write enables (ADR-006).
2. `State`, `Golden.step/run`, interrupt injection, context word.
3. `check_expect()` (R*, SP, PC, Z/N/C, FLAGS, M[x], OUT list).
4. Programs: one_operand, two_operand, memory, branch, call_ret, int_sw, reset_hlt.
5. CLI `archp golden`.

## Files to create/change
| Path | Change |
|---|---|
| `src/archp/golden.py` | New |
| `src/archp/cli.py` | `golden` sub-command |
| `programs/*.asm` | New (7) |
| `tests/test_golden.py` | New |

## Tests to add
| Test | Proves |
|---|---|
| `test_alu_rules[*]` | Every flag rule incl. borrow, shift-by-0, imm[4:0], SHR never C |
| `test_hw_interrupt_context_and_return` | Context word, return PC, flag restore |
| `test_program_expectations_on_golden[*]` | Hand-computed program results |

## Risks / open questions
| Item | Mitigation / decision |
|---|---|
| The model and the RTL could share a misreading of the spec | Programs' expectations are computed by hand from the brief, independently of both |

## Deviations (filled after execution)
None.
