# T-005: RTL building blocks: package, memory, register file, ALU, CCR

- **Status:** Done
- **Phase:** P2
- **Target:** W+2
- **Modules:** memory, register-file, ex1
- **Requirements:** REQ-P2-1, REQ-P2-7
- **Depends on:** T-002
- **Plan:** [PLAN-005](../implementationPlans/PLAN-005-rtl-blocks.md)
- **TCs:** TC-106
- **ADRs:** ADR-004, ADR-006
- **Session:** [S002](../sessions/2026-11-04-S002-full-build-run.md)
- **Branch / PR:** `feat/T-005-rtl-blocks` / PR #5

## Goal
Self-checked leaf components, integrated incrementally as the brief advises.

## Scope
- In: `archp_pkg`, `unified_memory` (M10K style, file init), `register_file`, `alu`, `ccr`; self-checking unit testbenches run by pytest via GHDL.
- Out: Pipeline.

## Acceptance criteria
- [x] Unit TBs pass in GHDL
- [x] ALU flag results match the golden model's ALU function for a sweep of vectors

## Definition of Done
- [x] Code + tests passing (CI green)
- [x] Module LLD updated
- [x] Explain it section complete
- [x] TCs updated
- [x] ADR (if decision made)
- [x] SystemGuides (if setup/usage changed)
- [x] Session log
- [x] PR squash-merged

## Notes / log
- **First run:** all 10 unit tests passed. To make sure the benches actually detect bugs, each was **mutation-tested**:
  - inverting the SUB carry;
  - removing the register-file bypass;
  - removing the RAM address register.
  Each mutation made its bench fail, and every mutation was reverted.
- `ghdl --synth` on each block: no latches. The memory is recognised as a RAM (`found RAM "ram", width: 32 bits, depth: 4096`). A `-Whide` warning (a variable named like a port) was fixed.

## Explain it (code-defense prep)
- **What changed:**
  - `archp_pkg`: opcodes, ALU ops, the control-word record `ctrl_t`, and the pipeline-register records.
  - `alu`, `ccr`, `register_file`, `unified_memory`.
  - Unit testbenches with a VHDL-93 hex helper package.
- **Why this design:**
  - **One adder:** `alu` uses a single 34-bit adder for ADD/IADD/address (A+B), SUB/CMP (A+~B+1) and INC (A+0+1). The carry-in is folded in as an extra LSB so Quartus builds one carry chain.
  - **CCR:** a separate block with explicit write priority (RTI ⟂ EX2-clear < EX1-update), as ADR-006 requires.
  - **Memory:** written in Intel's single-port inference template (registered address, combinational array read), so Quartus maps it to M10K. A plain `std.textio` loader runs only in simulation, wrapped in `synthesis translate_off`.
- **How it works:**
  - **`alu.vhd`:**
    - `bx/cin` select the adder inputs; `sum(33)` is the carry-out.
    - `shl_v` is `'0'&a` shifted left, so bit 32 is the last bit shifted out (the SHL carry).
    - `zn_we`/`c_we` say whether the operation defines the flags. The control unit's `flags_we` later gates them, so the LDD/STD address addition doesn't touch flags.
  - **`register_file.vhd`:** 8 x 32 flip-flops with synchronous reset. The read ports return `wd` when WB writes the same register in the same cycle (bypass).
  - **`unified_memory.vhd`:** `addr_reg <= addr` on the clock and `dout <= ram(addr_reg)`. Data is therefore valid one cycle after the address, as the brief specifies.
- **Likely examiner questions + answers:**
  - *How is the SUB carry produced?* `A + ~B + 1` gives carry-out = 1 when there is no borrow, so C = `not cout` (ADR-006 borrow convention; one constant flips it).
  - *Why is the memory read "synchronous" if `dout` is a combinational read of the array?* The address is registered. That is exactly how the M10K block works (input registers, unregistered output), and it is why the data appears one clock after the address.
  - *How do you know the memory becomes block RAM?* GHDL's synthesizer already infers a 4096 x 32 RAM from it. In Quartus, "Total block memory bits" in the Flow Summary is the proof (TC-212).
  - *Why a bypass in the register file?* An instruction in decode reading a register that WB writes in the same cycle would otherwise read the stale value, because the write lands at the clock edge. The bypass plays the role of "write in the first half, read in the second".
