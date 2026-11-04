# Module: decode

- **Owner:** TBD
- **Status:** Planned
- **Code:** `rtl/decode/control_unit.vhd`, `rtl/decode/decode_stage.vhd`
- **Tasks:** T-006, T-007, T-008
- **ADRs:** ADR-003, ADR-007, ADR-008, ADR-010, ADR-011

## Responsibility
Decode stage: control unit (opcode → control word), micro-op sequencer (SWAP, INT, interrupt), JMP/CALL redirect, RET/RTI wait, HLT, interrupt injection point, operand read. Does NOT execute or own the register storage.

## Interfaces
| Direction | Interface | Contract |
|---|---|---|
| Provides | | (filled when implemented) |
| Consumes | | |

## Data
(filled when implemented)

## Internal design
See [HLD](../../architecture/HLD.md) until implemented.

## Validation and failure modes
| Failure | Detection | Behavior |
|---|---|---|

## Config
| Key | Default | Meaning |
|---|---|---|

## Tests

## Known limitations
