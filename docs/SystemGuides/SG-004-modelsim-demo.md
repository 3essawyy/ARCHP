# SG-004: ModelSim demo — load a program, reset, run, show the waveform

- **Audience:** tester | examiner (the lab demo)
- **Last verified:** 2026-11-04. Do-file consistency is checked automatically (`tests/test_modelsim.py`, GHDL compiles in the exact `compile.do` order). **The ModelSim GUI run must be verified by the team** on a machine with ModelSim (TC-213).

## Prerequisites
- ModelSim–Intel FPGA Starter Edition (installed with Quartus Prime Lite 16.1), or any ModelSim/Questa.
- The repo set up per [SG-001](SG-001-setup-and-checks.md) (Python, to assemble programs).

## Steps
1. **Assemble the program.** For a TA program, first copy the IN values from its comments into a `#! in:` line (see [SG-003](SG-003-programs-and-assembler.md)):
   ```bash
   uv run archp asm programs/branch.asm
   ```
   This writes `programs/branch.mem` (RAM image), `.in` (IN.PORT values), `.intr` (INTR cycles), `.lst` (listing) and `.mif` (Quartus).
2. **Start ModelSim in `sim/modelsim`** (GUI: *File → Change Directory*, or from a shell):
   ```bash
   cd sim/modelsim && vsim
   ```
3. **Compile** (once, and after every RTL change), in the ModelSim transcript:
   ```
   do compile.do
   ```
4. **Load the program into the RAM, reset and run:**
   ```
   do run.do ../../programs/branch
   ```
   - This passes `branch.mem` as the RAM initialisation (`G_PROGRAM`) and feeds `.in`/`.intr`.
   - The testbench holds Reset for 2 cycles, the processor loads PC ← M[0], and the run stops automatically once HLT has drained the pipeline.
   - Bonus predictor build: `do run.do ../../programs/branch dynamic`.
5. **Read the waveform.** `wave.do` shows only CLK, Reset, Interrupt, IN.port, OUT.port, PC, SP, Flags (`0CNZ`) and R0–R7, in hex. Use the `.lst` file to map PC values to source lines.

### Manual stimulus (if the TA wants to drive the ports by hand)
- **IN.PORT:** `force -freeze /tb_processor/in_port 32'h00000005`, run, `noforce /tb_processor/in_port` to return control to the testbench.
- **Interrupt pulse:** `force /tb_processor/intr 1; run 10 ns; force /tb_processor/intr 0`. INTR is edge-triggered (ADR-007): one rising edge = one interrupt.

## Verify it worked
- The transcript ends with `TB_DONE HALTED cycles=N` and `final state written to …dump`.
- The `.dump` file lists the final R0–R7, SP, flags, the OUT values and memory. It should agree with `uv run archp check programs/branch.asm`, which prints PASS.

## Troubleshooting
| Symptom | Cause | Fix |
|---|---|---|
| `cannot open ...mem` | Program not assembled, or wrong relative path | Step 1; paths are relative to `sim/modelsim` |
| Run ends with `TIMEOUT` | Program has no HLT, or loops forever | Add HLT; check jump targets in the `.lst` |
| IN gives 0 | No `#! in:` values (list exhausted) | Add the values or force `in_port` |
| `vcom` order error after adding a file | `compile.do` not updated | Add it in dependency order; `uv run pytest tests/test_modelsim.py` checks this |
