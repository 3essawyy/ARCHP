# Module: ex2

- **Owner:** TBD
- **Status:** Implemented (T-006, T-007)
- **Code:** `rtl/execute/ex2_stage.vhd`
- **Tasks:** T-006, T-007
- **ADRs:** ADR-009, ADR-011, ADR-014

## Responsibility
Execute-2: branch resolution and flush/redirect, flag clear on taken jump, SP register and SP±1, final memory address and store-data formation.

## Interfaces
| Direction | Interface | Contract |
|---|---|---|
| Provides | `ex2_stage(d, flags) -> q, redirect, target, clr, sp_out` | SP register inside; branch unit |

## Data
(filled when implemented)

## Internal design
- **SP:** a 12-bit register, reset `0xFFF`. `sp_pm = SP+1` (pop) or `SP−1` (push), one adder; SP updates when a valid op has `stack /= NONE`.
- **Address:** push → SP, pop → `sp_pm`, otherwise `result(11:0)`.
- **Data:** on `mem_wr`, select by `wsel`: B, `0…ret_pc`, or `{CNZ, 0…, ret_pc}`. Otherwise the ALU result (one shared 32-bit field).

- **Branch unit:** `cond` = the flag picked by `br` (opcode[1:0]); `taken = valid and cond`; `redirect = valid and (taken xor pred)`; `target = taken ? d.target : d.ret_pc`; `clr = br when taken`.

## Validation and failure modes
| Failure | Detection | Behavior |
|---|---|---|

## Config
| Key | Default | Meaning |
|---|---|---|

## Tests
`programs/memory.asm`, `hazards_structural.asm`, fuzz programs (PUSH/POP).

## Known limitations
