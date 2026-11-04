# Module: hazards

- **Owner:** TBD
- **Status:** Planned
- **Code:** `rtl/execute/forwarding_unit.vhd`, HDU in `decode_stage.vhd`
- **Tasks:** T-006
- **ADRs:** ADR-006, ADR-008

## Responsibility
Forwarding unit (EX2/MEM/WB → EX1 operands A/B) and load-use hazard detection unit (ID stall), incl. the SWAP forwarding exception.

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
