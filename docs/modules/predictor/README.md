# Module: predictor

- **Owner:** TBD
- **Status:** Implemented (T-010)
- **Code:** `rtl/fetch/btb.vhd`
- **Tasks:** T-010
- **ADRs:** ADR-012

## Responsibility
Bonus 2-bit dynamic predictor: 8-entry BTB in fetch, EX2 update and mispredict recovery, `G_DYNAMIC_BP` generic.

## Interfaces
| Direction | Interface | Contract |
|---|---|---|
| Provides | `btb(lk_npc) -> pred_taken, pred_tgt` | Combinational lookup in fetch |
| Consumes | `up_valid, up_npc, up_taken, up_tgt` from EX2 | Update on every resolved JZ/JN/JC |
| Config | `G_DYNAMIC_BP` on core/top | `false` = ranked static build (no BTB generated) |

## Data
8 entries x (valid 1 + tag 9 + target 12 + counter 2) = 192 flip-flops (dynamic build only).

## Internal design
See the T-010 Explain it section. Key = branch address + 1; index `npc[2:0]`; tag `npc[11:3]`. Counter MSB = predict taken. Allocation only on taken (as `10`).

## Validation and failure modes
| Failure | Detection | Behavior |
|---|---|---|

## Config
| Key | Default | Meaning |
|---|---|---|

## Tests
Every program/fuzz/interrupt test in dynamic mode; `test_dynamic_predictor_speeds_up_loops`; `programs/smc_btb.asm`.

## Known limitations
Direct mapped: two branches whose `npc` share bits [2:0] evict each other. That only costs performance, never correctness.
