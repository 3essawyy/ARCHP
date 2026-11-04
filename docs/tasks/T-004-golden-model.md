# T-004: Golden ISA model and base test programs

- **Status:** Done
- **Phase:** P2
- **Target:** W+1
- **Modules:** golden-model
- **Requirements:** REQ-I*, REQ-G6, REQ-G7
- **Depends on:** T-003
- **Plan:** [PLAN-004](../implementationPlans/PLAN-004-golden-model.md)
- **TCs:** TC-105
- **ADRs:** ADR-005…ADR-010, ADR-013
- **Session:** [S002](../sessions/2026-11-04-S002-full-build-run.md)
- **Branch / PR:** `feat/T-004-golden-model` / PR #4

## Goal
An instruction-level executable specification used to check the RTL.

## Scope
- In: `golden.py` (state, step, run, interrupts at retired counts, IN queue, OUT log), `#! expect` checks, CLI `archp golden`, base programs per instruction group.
- Out: Cycle accuracy.

## Acceptance criteria
- [x] Unit tests for every instruction and flag rule in ADR-005/006
- [x] Programs' `#! expect` lines pass on the model

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
- **Test feedback:** all 7 programs' hand-computed `#! expect` values matched the model on the first run (an independent cross-check of the spec reading). One failing test, `test_stack_wraps_and_sp_reset`, was wrong in the *test* (it assumed SP=000 after POP+PUSH); rewritten as `test_stack_wraps_modulo_4k`. mypy caught a shadowed exception variable in the CLI.

## Explain it (code-defense prep)
- **What changed:**
  - `archp.golden` is an instruction-level model of the ISA: a `State` holding R0–R7, PC, SP, Z/N/C, memory, the OUT log, the retired count and the interrupt log.
  - `Golden.step/run` executes it.
  - `alu()` is the reference for every flag rule.
  - `check_expect()` evaluates `#! expect` lines.
  - The CLI is `archp golden prog.asm [--intr N…]`.
  - 7 base programs live in `programs/`.
- **Why this design:** The RTL is checked against an independent, readable statement of the ISA (ADR-013). Any disagreement means either the RTL or our reading of the spec is wrong, and the expect lines (worked out by hand) arbitrate. Interrupts are modelled at *retired-instruction counts* so the model doesn't need to know pipeline timing.
- **How it works:**
  - **Construction:** `Golden(image, inputs, intr_points)` loads the 4096-word image and sets PC ← M[0].
  - **`step()`:**
    1. Take any due hardware interrupts: push `{C N Z << 29 | PC}`, then PC ← M[1].
    2. Decode the word with `isa.decode` and execute it per ADR-005…010.
    3. Increment `retired`.
  - **HLT** retires and leaves PC on itself.
  - **Arithmetic:** PC/SP arithmetic is modulo 4096 (ADR-009). `SUB_CARRY_IS_BORROW` selects the C convention (ADR-006).
- **Likely examiner questions + answers:**
  - *Why a Python model at all?* It is the oracle. The full register file, memory and OUT log are compared after every RTL test program, so a hazard bug that corrupts any state is caught, not only the values someone thought to check.
  - *How does the model handle interrupts whose timing depends on the pipeline?* The RTL testbench logs how many instructions had retired when each interrupt was taken. The model injects the interrupt at exactly that point and must then produce identical results.
  - *What does `INT 0` push?* `X[SP] ← {flags, PC+1}`. For `INT 0` at 0x13 with C=1, N=0, Z=1 that is `A0000014` (see `programs/int_sw.asm`).
