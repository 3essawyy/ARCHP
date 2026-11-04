# Phase 1 acceptance TCs

Status tracked in [README.md](README.md).

### TC-101 — Phase 1 design report covers every required element
- **Proves:** REQ-P1-1…4
- **Steps:** Review `docs/reports/phase1-report.pdf` against the brief.
- **Expected:**
  - instruction format, the opcode of every instruction and the bit details;
  - a digital schematic showing the ALU, registers and memory blocks, every interconnection with its width, and the control unit design;
  - the pipeline stages, and every pipeline register with its size, inputs and connections;
  - hazards and solutions, covering data forwarding and static branch prediction.

### TC-102 — Clean setup from docs
- **Proves:** reproducibility
- **Steps:** Fresh Ubuntu machine/container; follow SG-001 only; run `uv run poe check`.
- **Expected:** Green; no undocumented step.

### TC-103 — Instruction encodings
- **Proves:** REQ-P1-1, REQ-P2-3
- **Type:** Automated (`tests/test_isa.py`, `tests/test_assembler.py`)
- **Expected:** Each mnemonic with each operand form encodes to the HLD §3.2 bit pattern; round-trip through the decoder helper.

### TC-104 — TA program format
- **Proves:** REQ-P2-3, REQ-E1
- **Type:** Automated
- **Expected:**
  - `.ORG`, bare-hex numbers, raw data words, `#` and `;` comments, labels, any letter case and optional commas are all accepted.
  - Errors carry line numbers.
  - `.mem` is 4096 lines and `.mif` is valid.

### TC-105 — Golden ISA model
- **Proves:** REQ-I*, ADR-005…010
- **Type:** Automated (`tests/test_golden.py`)
- **Expected:** Every instruction and flag rule, the stack, INT/RTI context word, reset vector and HLT behave as specified; programs' `#! expect` lines pass.

### TC-106 — Unit testbenches
- **Proves:** REQ-P2-1
- **Type:** Automated (`tests/test_rtl_units.py` runs `tb/unit/*.vhd` in GHDL)
- **Expected:** All self-checking assertions pass; ALU flags equal the golden ALU for a vector sweep.
