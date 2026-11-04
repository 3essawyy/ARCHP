# Module: ex1

- **Owner:** TBD
- **Status:** Implemented (T-006)
- **Code:** `rtl/execute/alu.vhd`, `rtl/execute/ccr.vhd`, `rtl/execute/ex1_stage.vhd`
- **Tasks:** T-005, T-006
- **ADRs:** ADR-005, ADR-006, ADR-014

## Responsibility
Execute-1: ALU (add/sub/and/not/inc/pass/shift/in/setc, flags), operand-B immediate select, IN.PORT sample, CCR (condition-code register with EX1/EX2/WB write sources).

## Interfaces
| Direction | Interface | Contract |
|---|---|---|
| Provides | `alu(op, a, b, shamt, in_port) -> result, z, n, c, zn_we, c_we` | Combinational; flags per ADR-006 |
| Provides | `ccr(... ex1_*, ex2_clr, wb_rti, wb_flags) -> flags` | C N Z; priority RTI, then EX2 clear, then EX1 update |

## Data
(filled when implemented)

## Internal design
- **ALU ops:** ADD, SUB, AND, NOT, INC, PASSA, PASSB, SHL, SHR, IN, SETC (4-bit `alu_op_t`).
- **One adder:** `sum = ('0'&a&'1') + ('0'&bx&cin)`, with `bx` = B, ~B or 0 and `cin` = 0 or 1.
- **SHL carry:** bit 32 of `('0'&a) << shamt`.
- **SUB carry:** `not cout` while `C_SUB_CARRY_IS_BORROW` is set.

- **Operands:** `fa`/`fb` come from 4:1 muxes driven by `forwarding_unit` (register, EX2, MEM, WB).
- **Immediate:** `imm_ext` sign- or zero-extends by `imm_sext`. `alu_b = imm_ext when b_imm else fb`.
- **Store data:** `q.b = fb`, never the immediate. A mutation proved it matters.
- **Live gate:** `live = valid and not flush` gates the CCR writes, `in_rd` and the output register value.

## Validation and failure modes
| Failure | Detection | Behavior |
|---|---|---|

## Config
| Key | Default | Meaning |
|---|---|---|

## Tests
`test_alu_matches_golden`, all program tests.
`test_alu_matches_golden` (≈4,500 vectors vs `archp.golden.alu`), `test_ccr` (TC-106).

## Known limitations
