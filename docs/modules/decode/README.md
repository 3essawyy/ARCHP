# Module: decode

- **Owner:** TBD
- **Status:** Implemented (T-006: HDU, replay, SWAP, HLT; control flow T-007; interrupts T-008)
- **Code:** `rtl/decode/control_unit.vhd`, `rtl/decode/decode_stage.vhd`
- **Tasks:** T-006, T-007, T-008
- **ADRs:** ADR-003, ADR-007, ADR-008, ADR-010, ADR-011

## Responsibility
Decode stage: control unit (opcode → control word), micro-op sequencer (SWAP, INT, interrupt), JMP/CALL redirect, RET/RTI wait, HLT, interrupt injection point, operand read. Does NOT execute or own the register storage.

## Interfaces
| Direction | Interface | Contract |
|---|---|---|
| Provides | `id_ex1_d`, `replay`, `redirect`, `target`, `block_fetch`, `halted`, `halt_pc`, `ra_addr`, `rb_addr` | |
| Consumes | `instr` (RAM output), `fetch_valid`, `id_pc`, `id_npc`, `flush`, `mem_busy`, `pcl_valid`, `ex1_ctrl`, `ex2_ctrl`, `ra_data`, `rb_data` | |

## Data
(filled when implemented)

## Internal design
- **`control_unit`:** a combinational table, opcode (+ `phase`, `hw`) → `ctrl_t` + `use_a`/`use_b`.
- **Valid input:** `valid_in = fetch_valid and not halted and not flush`.
- **HDU:** `lu_stall` when a used source equals `rd` of a valid `wb_mem` op in EX1 or EX2. The result is a bubble plus `replay`.
- **SWAP:** in phase 0, issue uop1 (`rd ← R[Ra]`) only if `mem_busy = 0`, then replay. Phase 1 issues uop2 (`Ra ← R[Rb]`, `swap2`, `retire`).
- **HLT:** issues a retiring NOP micro-op and sets `halted` and `halt_pc`. `block_fetch = halted or (valid HLT)`.

- **JMP/CALL:** `redirect = valid_in and (JMP or CALL)`, `target = instr(11:0)`. CALL also issues its push micro-op.
- **RET/RTI:** `start_wait` sets `wait_r` (fetch blocked, decode input ignored); `pcl_valid` clears it.
- **Flush:** clears `phase`, `wait_r` and `halted_r` (undoes a wrong-path SWAP/RET/HLT).

## Validation and failure modes
| Failure | Detection | Behavior |
|---|---|---|

## Config
| Key | Default | Meaning |
|---|---|---|

## Tests
`tests/test_programs.py` (TC-201…205), mutation: removing the EX2 load-use check fails 14 tests.

## Known limitations
