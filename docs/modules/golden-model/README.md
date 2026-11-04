# Module: golden-model

- **Owner:** TBD
- **Status:** Implemented (T-004)
- **Code:** `src/archp/golden.py`
- **Tasks:** T-004
- **ADRs:** ADR-005…ADR-010, ADR-013

## Responsibility
Instruction-level executable specification of the ISA used to check the RTL.

## Interfaces
| Direction | Interface | Contract |
|---|---|---|
| Provides | `Golden(image, inputs, intr_points).run() -> State` | Final architectural state + OUT log + retired count + interrupt log |
| Provides | `alu(op, a, b, imm) -> AluOut` | Reference result and flags with write enables |
| Provides | `check_expect(state, items) -> list[str]` | Empty list = all `#! expect` items hold |
| Consumes | `archp.isa` | decode, constants |

## Data
`State`: regs[8], pc (12 bit), sp (12 bit), z/n/c, mem[4096], out[], halted, retired, hw_ints[].

## Internal design
See the T-004 Explain it section. `SUB_CARRY_IS_BORROW` is the single switch for the SUB/CMP carry convention (ADR-006).

## Validation and failure modes
| Failure | Detection | Behavior |
|---|---|---|

## Config
| Key | Default | Meaning |
|---|---|---|

## Tests
`tests/test_golden.py` (TC-105); all `programs/*.asm` must carry `#! expect` lines that pass on the model.

## Known limitations
Not cycle-accurate by design; it cannot judge *where* an interrupt is taken, only the results given that point.
