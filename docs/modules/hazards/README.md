# Module: hazards

- **Owner:** TBD
- **Status:** Implemented (T-006)
- **Code:** `rtl/execute/forwarding_unit.vhd`, HDU in `decode_stage.vhd`
- **Tasks:** T-006
- **ADRs:** ADR-006, ADR-008

## Responsibility
Forwarding unit (EX2/MEM/WB → EX1 operands A/B) and load-use hazard detection unit (ID stall), incl. the SWAP forwarding exception.

## Interfaces
| Direction | Interface | Contract |
|---|---|---|
| Provides | `forwarding_unit(ra, rb, swap2, ex2/mem/wb ctrl) -> sel_a, sel_b` | "00" reg, "01" EX2, "10" MEM, "11" WB |
| Provides | HDU in `decode_stage` | `lu_stall` |

## Data
(filled when implemented)

## Internal design
- **Forwarding priority:** EX2 (not a load, and not to SWAP uop2), then MEM (not a load), then WB (any write, incl. load data). A match needs `valid and reg_we and rd = src`.
- **HDU:** stalls while a load producing a used source is in EX1 or EX2.

## Validation and failure modes
| Failure | Detection | Behavior |
|---|---|---|

## Config
| Key | Default | Meaning |
|---|---|---|

## Tests
Mutation evidence (T-006 notes): removing EX2 or WB forwarding fails 44/46 tests; removing the regfile bypass fails 36; the SWAP exception, 29.

## Known limitations
