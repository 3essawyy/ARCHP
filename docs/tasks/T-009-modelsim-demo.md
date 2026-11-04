# T-009: ModelSim do-files, waveform and demo guide

- **Status:** Done
- **Phase:** P2
- **Target:** W+4
- **Modules:** sim
- **Requirements:** REQ-P2-2, REQ-E2
- **Depends on:** T-008
- **Plan:** [PLAN-009](../implementationPlans/PLAN-009-modelsim-demo.md)
- **TCs:** TC-213
- **ADRs:** ADR-002
- **Session:** [S002](../sessions/2026-11-04-S002-full-build-run.md)
- **Branch / PR:** `feat/T-009-modelsim-demo` / PR #9

## Goal
The TA demo flow: compile, load a program, reset, run, clean waveform with the required signals only.

## Scope
- In: `sim/modelsim/compile.do`, `run.do`, `wave.do`; SG-004 demo guide.
- Out: —

## Acceptance criteria
- [x] Do-files reference only existing files/signals (checked by a test)
- [x] SG-004 written; team verifies in ModelSim

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
- The do-files are checked automatically:
  - `compile.do` must list exactly the RTL + TB sources, in an order GHDL can compile one by one. A mutation swapping `forwarding_unit` and `ex1_stage` makes the test fail.
  - `wave.do` may only name existing testbench signals, and `run.do` only existing generics.
- The assembler now also writes `.in`/`.intr` stimulus files, so ModelSim gets the same IN values and INTR cycles as `archp check`.
- **Not verifiable here:** the actual ModelSim GUI run (no ModelSim in the container). TC-213 stays "team to run".

## Explain it (code-defense prep)
- **What changed:**
  - `sim/modelsim/compile.do` compiles all VHDL-93 sources in dependency order.
  - `run.do <stem> [dynamic]` loads `<stem>.mem` into the RAM through the `G_PROGRAM` generic, feeds `.in`/`.intr`, runs until HLT and writes `<stem>.dump`.
  - `wave.do` shows only the required signals.
  - SG-004 is the demo guide.
- **Why this design:**
  - **One testbench:** the same `tb_processor` runs in GHDL (CI) and ModelSim (demo), so what the TA sees is what CI checks.
  - **Generic-based loading:** the RAM loads through a generic, not `mem load`, so it works identically in both simulators.
  - **Clean wave:** the brief asks for the main signals only.
- **How it works:**
  - `run.do` reads its arguments (`$1`, `$2`), builds the `vsim -g…` command, then sources `wave.do` and runs `run -all`.
  - The testbench stops the clock when the core is halted and idle, so `run -all` returns by itself.
- **Likely examiner questions + answers:**
  - *How do you load a new program?* `uv run archp asm prog.asm`, then `do run.do ../../programs/prog`. The processor starts at M[0] after reset.
  - *Can I drive IN.PORT myself?* Yes: `force -freeze /tb_processor/in_port 32'h…`. `noforce` hands it back to the testbench.
  - *Why is PC shown as 32 bits when it is 12 bits internally?* It is the zero-extended view, `dbg_pc` (ADR-009).
