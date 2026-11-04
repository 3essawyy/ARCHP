# Module: fetch

- **Owner:** TBD
- **Status:** Implemented (T-006; redirects completed in T-007)
- **Code:** `rtl/fetch/fetch_unit.vhd`
- **Tasks:** T-006, T-007, T-010
- **ADRs:** ADR-004, ADR-009, ADR-011

## Responsibility
Fetch stage: PC register, next-address priority mux (WB pc-load, EX2 redirect, decode JMP/CALL, replay, PC), fetch enable vs. memory arbitration, IF/ID valid and `id_pc`. Does NOT decode instructions.

## Interfaces
| Direction | Interface | Contract |
|---|---|---|
| Provides | `fetch_addr`, `fetch_valid` (fv), `id_pc`, `id_npc`, `pc_out` | IF/ID side register; RAM output is the instruction |
| Consumes | `pcl_valid/pcl_addr` (WB), `ex2_redirect/target`, `id_redirect/target`, `id_replay`, `mem_busy`, `block_fetch` | Priority as listed |

## Data
(filled when implemented)

## Internal design
- **`target` priority:**
  1. PC load from the RAM output (`pcl_valid` or boot `bootq`);
  2. EX2 redirect;
  3. ID redirect (JMP/CALL);
  4. replay (`id_pc`);
  5. `pc`.
- **`fetch_en = not mem_busy and not boot and (not block_fetch or pcl_valid or bootq)`.**
  - Enabled: `pc ← target+1`, `id_pc ← target`, `fv ← 1`.
  - Otherwise: `pc ← target`, `fv ← 0`.
- **Static build:** `id_npc = pc` (exact whenever `fv = 1`), which saves a 12-bit register.
- **Boot:** reset sets `pc = 0`, `boot = 1`. The boot cycle reads M[0]; the next cycle (`bootq`) loads it as `target`.

## Validation and failure modes
| Failure | Detection | Behavior |
|---|---|---|

## Config
| Key | Default | Meaning |
|---|---|---|

## Tests
Covered by `tests/test_programs.py`, `tests/test_timing.py` (fetch stall = 1 cycle per memory instruction).

## Known limitations
