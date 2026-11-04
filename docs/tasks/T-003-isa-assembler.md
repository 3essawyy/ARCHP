# T-003: ISA definition and assembler

- **Status:** Done
- **Phase:** P1
- **Target:** W+1
- **Modules:** assembler
- **Requirements:** REQ-P1-1, REQ-P2-3, REQ-E1
- **Depends on:** T-002
- **Plan:** [PLAN-003](../implementationPlans/PLAN-003-isa-assembler.md)
- **TCs:** TC-103, TC-104
- **ADRs:** ADR-003, ADR-005
- **Session:** [S002](../sessions/2026-11-04-S002-full-build-run.md)
- **Branch / PR:** `feat/T-003-isa-assembler` / PR #3

## Goal
One Python source of truth for the encoding (`archp.isa`) and an assembler that reads TA-format programs and writes `.mem` (GHDL/ModelSim) and `.mif` (Quartus).

## Scope
- In: `isa.py` tables, `assembler.py` (labels, `.ORG`, data words, hex/decimal/negative numbers, `#` and `;` comments, case-insensitive), `#!` directives, CLI `archp asm`, SG-003.
- Out: Disassembler beyond what tests need.

## Acceptance criteria
- [x] Every instruction encodes per HLD §3.2 (table-driven test)
- [x] TA-format sample programs assemble
- [x] Clear errors with line numbers for bad input
- [x] `.mem` is 4096 lines of 8 hex digits; `.mif` valid

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
- **Test feedback 1:** a data word holding a label (`.ORG 0` / `start`) was rejected as an unknown mnemonic. Fixed: a lone identifier on a line is a data word whose value is that label.
- **Test feedback 2:** last term's TA `Branch.txt` line 19 really contains `IADD R1, R2, R3` (a register where Imm belongs). The assembler now says `expected a number or label, got register 'R3'` with the line number. We deliberately keep this an error rather than guessing; the team fixes the typo if a TA file has one.
- **Test feedback 3:** `TwoOperand.txt` expects "carry as not borrow" for SUB. Asked the user. Rule: brief silent → follow last term's implementation (borrow). Recorded in ADR-006 with a one-constant switch.

## Explain it (code-defense prep)
- **What changed:**
  - `archp.isa` is the encoding table: opcodes, operand → field placement, `encode`/`decode`/`disassemble`.
  - `archp.assembler` is a two-pass assembler.
  - `archp asm` writes `.mem` (GHDL/ModelSim), `.mif` (Quartus) and `.lst` (listing for the demo).
- **Why this design:** One table (`SPECS`) drives both encoding and decoding, so the assembler, the golden model and the tests can never disagree on bit positions. Placing each operand in the field of the *port that uses it* (Ra = read port A, Rb = read port B, Rd = write port) lets the hardware wire the register-file addresses straight from instruction bits (ADR-003).
- **How it works:**
  - **Pass 1** walks the lines. It records `#!` directives, strips `#`/`;` comments, defines labels at the current location, handles `.ORG`, and queues instructions and data words with their addresses.
  - **Pass 2** resolves labels and numbers (hex by default) and range-checks each operand kind (signed 16, unsigned 16, 12-bit target, INT index 0/1). It detects overlapping addresses and calls `isa.encode`.
  - **Outputs:** `mem_text` writes 4096 lines of 8 hex digits; `mif_text` writes the Quartus MIF with zero ranges compressed.
- **Likely examiner questions + answers:**
  - *Why do NOT and INC put Rdst in two fields?* The ALU reads its operand from port A (`Ra`) and the result is written to `Rd`. Duplicating the register number in the encoding avoids a mux in decode.
  - *Why does STD put the base in Ra and the data in Rb?* The base feeds the ALU adder (port A), like LDD's base, and the store data rides along on port B, like PUSH. So LDD/STD/PUSH share datapath wiring.
  - *How are negative immediates encoded?* As 16-bit two's complement. IADD and offsets accept −8000…FFFF; LDM accepts only 0…FFFF (it is zero-extended, ADR-005).
  - *What happens to the unused opcodes 11101–11111?* They execute as NOP.
