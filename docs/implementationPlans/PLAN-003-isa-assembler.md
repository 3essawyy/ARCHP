# PLAN-003: ISA definition and assembler (for T-003)

- **Task:** [T-003](../tasks/T-003-isa-assembler.md)
- **Status:** Executed
- **Date:** 2026-11-04

## Approach
A table-driven ISA module (`SPECS`: mnemonic → opcode + operand kinds + target fields) shared by the assembler, the golden model and the tests. The assembler is two-pass so labels can be used before they are defined. It accepts the TA test format exactly, because TA programs are what get graded.

## Steps
1. `isa.py`: `Op`, `Field`, `Arg`, `SPECS`, `encode`, `decode`, `disassemble`, `sext16`, constants (vectors, SP reset, context-word layout).
2. `assembler.py`: pass 1 (directives, comments, labels, `.ORG`, items), pass 2 (operands, ranges, overlaps), `.mem`/`.mif`/`.lst` writers.
3. CLI `archp asm`.
4. Tests: a table of every instruction (TC-103) and the format, errors, last-term TA programs and output formats (TC-104).

## Files to create/change
| Path | Change |
|---|---|
| `src/archp/isa.py`, `src/archp/assembler.py` | New |
| `src/archp/cli.py` | `asm` sub-command |
| `tests/test_isa.py`, `tests/test_assembler.py`, `tests/data/ta_lastterm/*` | New |

## Tests to add
| Test | Proves |
|---|---|
| `test_encoding[*]` (31 cases) | HLD §3.2 bit patterns, field placement, bits 17:16 = 0 |
| `test_disassemble_round_trip` | decode/disassemble consistent with encode |
| `test_errors_have_line_numbers[*]` | Every error class reported with `file:line` |
| `test_last_term_ta_programs_assemble` | The real TA format is accepted |
| `test_mem_and_mif_formats` | Loadable output files |

## Risks / open questions
| Item | Mitigation / decision |
|---|---|
| Numbers are hex by default, so a label like `face` could be read as a number | Labels win over numbers; a single-identifier line is treated as a label reference |

## Deviations (filled after execution)
- Added the lone-label data word and the register-as-immediate error after test feedback (see the T-003 notes).
