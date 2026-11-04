# Module: pipeline

- **Owner:** TBD
- **Status:** Implemented (T-006)
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

Stalls never reach past ID, so the registers have no enable. Bubbles and flushes are produced by the stage that computes `d` (decode emits `C_ID_EX1_NOP`; EX1 emits `C_EX1_EX2_NOP` when flushed).

## Validation and failure modes
| Failure | Detection | Behavior |
|---|---|---|

## Config
| Key | Default | Meaning |
|---|---|---|

## Tests
All program tests.
Covered by the core tests from T-006.

## Known limitations
