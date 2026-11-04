# Module: pipeline

- **Owner:** TBD
- **Status:** In progress (records defined in T-005)
- **Code:** `rtl/pkg/archp_pkg.vhd`, `rtl/pipeline/*.vhd`
- **Tasks:** T-006
- **ADRs:** ADR-004

## Responsibility
The four pipeline registers ID/EX1, EX1/EX2, EX2/MEM, MEM/WB: record types, reset, bubble insertion, flush.

## Interfaces
| Direction | Interface | Contract |
|---|---|---|
| Provides | `ctrl_t`, `id_ex1_t`, `ex1_ex2_t`, `ex2_mem_t`, `mem_wb_t` + `*_NOP` constants | `rtl/pkg/archp_pkg.vhd` |

## Data
(filled when implemented)

## Internal design
See HLD §5 for the field list. The full `ctrl_t` rides in every stage register; fields a stage never reads have no fan-out and are removed by synthesis.

## Validation and failure modes
| Failure | Detection | Behavior |
|---|---|---|

## Config
| Key | Default | Meaning |
|---|---|---|

## Tests
Covered by the core tests from T-006.

## Known limitations
