# Module: assembler

- **Owner:** TBD
- **Status:** Implemented (T-003)
- **Code:** `src/archp/isa.py`, `src/archp/assembler.py`
- **Tasks:** T-003
- **ADRs:** ADR-003, ADR-005

## Responsibility
ISA tables (single source of truth for encoding) and the assembler: TA-format `.asm` → `.mem` / `.mif`, `#!` directives.

## Interfaces
| Direction | Interface | Contract |
|---|---|---|
| Provides | `isa.SPECS`, `encode`, `decode`, `disassemble`, `sext16`, constants | Encoding per HLD §3.2 |
| Provides | `assembler.assemble(text) -> Program` | words, origin, labels, code set, `Directives` |
| Provides | `mem_text`, `mif_text`, `listing_text`, `write_outputs` | `.mem` = 4096 x 8 hex digits; `.mif` Quartus |
| Provides | CLI `archp asm file [-o stem]` | exit code 1 + `file:line: message` on error |

## Data
- **Input:** TA-format assembly (see [SG-003](../../SystemGuides/SG-003-programs-and-assembler.md)).
- **`Directives`:** `inputs`, `intr_cycles`, `expect`, `max_cycles` from `#!` lines.

## Internal design
Two passes (see T-003 Explain it). Operand kinds: `REG` (fields list), `SIMM` (−8000…FFFF), `UIMM` (0…FFFF), `TARGET` (0…FFF), `INDEX` (0/1), `MEM` (`off(Rn)`, signed offset + base into `Ra`).

## Validation and failure modes
| Failure | Detection | Behavior |
|---|---|---|
| Unknown mnemonic, bad register, operand count | pass 1/2 | `AsmError file:line` |
| Out-of-range immediate/target/index | `ranged()` | `AsmError` |
| Register where a number belongs | `value()` | `AsmError` ("got register") |
| Two items at one address | pass 2 | `AsmError` naming the first line |

## Config
| Key | Default | Meaning |
|---|---|---|

## Tests
`tests/test_isa.py` (TC-103), `tests/test_assembler.py` (TC-104).

## Known limitations
