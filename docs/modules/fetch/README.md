# Module: fetch

- **Owner:** TBD
- **Status:** Planned
- **Code:** `rtl/fetch/fetch_unit.vhd`
- **Tasks:** T-006, T-007, T-010
- **ADRs:** ADR-004, ADR-009, ADR-011

## Responsibility
Fetch stage: PC register, next-address priority mux (WB pc-load, EX2 redirect, decode JMP/CALL, replay, PC), fetch enable vs. memory arbitration, IF/ID valid and `id_pc`. Does NOT decode instructions.

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
