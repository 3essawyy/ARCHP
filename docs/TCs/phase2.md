# Phase 2 acceptance TCs

Status tracked in [README.md](README.md). Unless noted, each TC is automated by `tests/test_programs.py`. It assembles the listed `programs/*.asm`, runs them on the golden model and on the RTL (GHDL, both predictor builds from T-010 on) and requires an identical architectural dump (ADR-013) plus all `#! expect` lines.

### TC-201 — One-operand instructions
- **Proves:** REQ-I1…I3, REQ-E5 (instructions)
- **Programs:** `programs/one_operand.asm`
- **Expected:** NOP, SETC, NOT, INC, IN, OUT and their flags correct; OUT log matches.

### TC-202 — Two-operand instructions
- **Proves:** REQ-I4…I8
- **Programs:** `programs/two_operand.asm`
- **Expected:** MOV, SWAP, ADD, SUB, AND, IADD, CMP, SHL, SHR with flag rules of ADR-006.

### TC-203 — Memory and stack instructions
- **Proves:** REQ-I9…I11
- **Programs:** `programs/memory.asm`
- **Expected:** PUSH, POP, LDM, LDD, STD; full memory image equal.

### TC-204 — Data hazards
- **Proves:** REQ-E5 (data hazards), REQ-P1-4
- **Programs:** `programs/hazards_data.asm`
- **Expected:**
  - RAW at distances 1, 2, 3, 4 on both operands;
  - load-use at distances 1, 2, 3;
  - load → store data, flags → jump, back-to-back PUSH/POP.
  - All correct with no NOPs inserted by the programmer.

### TC-204a — Random hazard-dense programs
- **Proves:** REQ-E5 (data + structural hazards)
- **Type:** Automated (`tests/test_programs.py::test_fuzz_*`, generator `archp.fuzz`)
- **Expected:** 40 seeds x 70 random instructions (ALU, SWAP, LDD/STD, PUSH/POP, IN/OUT): RTL == golden.

### TC-204b — Hazard penalties
- **Proves:** HLD §6 timing claims
- **Type:** Automated (`tests/test_timing.py`)
- **Expected:** load-use 2/1/0, POP-use 2, ALU RAW 0, store 1, PUSH+POP 2, SWAP 1 cycles.

### TC-205 — Structural hazards
- **Proves:** REQ-E5 (structural hazards)
- **Programs:** `programs/hazards_structural.asm`
- **Expected:** Runs of memory instructions (fetch starvation), SWAP in every hazard context, and SWAP after a load all produce correct results.

### TC-206 — Control hazards
- **Proves:** REQ-E5 (control hazards), REQ-I12, REQ-I13
- **Programs:** `programs/branch.asm`, `programs/call_ret.asm`, `programs/control_corners.asm` + `test_fuzz_control_flow` (40 random programs)
- **Expected:**
  - JZ/JN/JC taken and not taken, with the tested flag cleared only when taken;
  - flag produced right before the jump;
  - back-to-back jumps and nested CALL/RET;
  - jump over instructions that must not execute.

### TC-207 — Interrupts and INT/RTI
- **Proves:** REQ-G5, REQ-G6, REQ-I14
- **Programs:** `programs/interrupt.asm` (+ sweep: one INTR pulse at every cycle of a branchy program), `programs/int_sw.asm`
- **Expected:** Every run equals the golden model replayed at the logged interrupt points; the saved flags are restored; no interrupt is lost or duplicated.

### TC-208 — Reset vector and HLT
- **Proves:** REQ-G7, REQ-I1
- **Programs:** `programs/reset_hlt.asm`
- **Expected:** Execution starts at M[0]; instructions before HLT complete; nothing after HLT executes; INTR after HLT is ignored.

### TC-209 — TA-style programs
- **Proves:** REQ-E1
- **Programs:** `programs/ta_*.asm` (previous-term TA programs adapted to this term's vectors)
- **Expected:** RTL == golden and the comment expectations hold.

### TC-210 — Dynamic predictor build
- **Proves:** REQ-E5 (bonus), REQ-E7
- **Expected:** Every program above passes with `G_DYNAMIC_BP=true`; `programs/loop.asm` takes fewer cycles than in the static build.

### TC-211 — Synthesizable, no latches
- **Proves:** REQ-E6, REQ-A1
- **Type:** Automated (`tests/test_synth.py`: `ghdl --synth --std=93c processor_top`)
- **Expected:** Synthesis succeeds; no latch warnings; both generic values.

### TC-212 — Quartus full compile
- **Proves:** REQ-E3, REQ-E4, REQ-P2-6, REQ-P2-7
- **Type:** Manual (team), SG-005
- **Expected:** Quartus Prime Lite 16.1 with default settings, 5CSEMA5F31C6. The compile produces a `.sof`, and Total block memory bits = 131,072. Record ALMs and registers for both builds.

### TC-213 — ModelSim waveform
- **Proves:** REQ-E2, REQ-P2-2
- **Type:** Manual (team), SG-004; do-file consistency automated
- **Expected:** `do run.do <program>` loads the memory, resets and runs. The wave shows only CLK, Reset, Interrupt, IN.port, OUT.port, R0–R7, PC, SP and Flags.

### TC-214 — Phase 2 report
- **Proves:** REQ-P2-4, REQ-P2-5, REQ-P2-6
- **Expected:** Design changes since Phase 1 with justification, the hazards table, and Flow Summary screenshot(s).
