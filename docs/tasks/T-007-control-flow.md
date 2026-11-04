# T-007: Control flow: static prediction, flush, JMP/CALL/RET

- **Status:** Done
- **Phase:** P2
- **Target:** W+3
- **Modules:** fetch, decode, ex2
- **Requirements:** REQ-I12, REQ-I13, REQ-P1-4, REQ-E5
- **Depends on:** T-006
- **Plan:** [PLAN-007](../implementationPlans/PLAN-007-control-flow.md)
- **TCs:** TC-206
- **ADRs:** ADR-011
- **Session:** [S002](../sessions/2026-11-04-S002-full-build-run.md)
- **Branch / PR:** `feat/T-007-control-flow` / PR #7

## Goal
Correct branches with not-taken static prediction and zero-penalty JMP/CALL.

## Scope
- In: Branch unit, flush, flag clear, decode redirects, RET wait/pc-load.
- Out: INT/RTI.

## Acceptance criteria
- [x] Branch programs (taken/not taken, flag clear, nested CALL/RET, back-to-back branches) pass RTL == golden

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
- **Design feedback before coding:** a wrong-path HLT (behind a taken JZ) would set `halted` before the flush arrives. Decode now undoes `halted`, `wait` and the micro-op `phase` on a flush. `programs/control_corners.asm` proves it.
- **Results:** `branch.asm`, `call_ret.asm`, `control_corners.asm` and 40 random programs with forward branches and CALL/RET all give RTL == golden.
- **Mutation checks:**

| Mutation | Failing tests |
|---|---|
| Wrong-path HLT not undone | 1 |
| Taken jump keeps its flag | 5 |
| EX1 not flushed | 21 |
| Flushed EX1 still writes Z/N | 1 |
| ID not flushed | 19 |
| "RET does not stop fetch" | 0, an **equivalent mutant**: decode already discards everything while `wait` is set. Fetch blocking is kept so PC visibly freezes in the waveform. |

- **Measured penalties** match HLD §6.3: taken JZ 2, JMP 0, CALL+RET 4. Pinned in `tests/test_timing.py`.

## Explain it (code-defense prep)
- **What changed:**
  - **EX2 branch unit:** flag test, `taken`, `redirect = taken xor pred`, flag clear.
  - **Flush:** ID and EX1 are killed by an EX2 redirect.
  - **Decode:** JMP/CALL redirect the fetch address in the same cycle; RET/RTI set `wait` until WB loads PC; a flush undoes speculative decode state.
- **Why this design:**
  - **Static not-taken:** the cheapest correct prediction (ADR-011).
  - **JMP/CALL in decode:** their targets are absolute immediates sitting in the RAM output during decode. Steering the RAM address in that same cycle costs zero bubbles.
  - **No flag forwarding:** the CCR is written in EX1 and read in EX2, so every older flag writer has already written it.
- **How it works:**
  - **EX2, cycle t:** `cond` = the flag selected by `br` (= opcode[1:0]). `taken = valid and cond`. If `taken xor pred`:
    1. `flush` gates EX1's CCR writes and output register, and decode's `valid_in`;
    2. the fetch unit takes `ex2_target` (the `imm`, or `ret_pc` when a predicted-taken branch falls through);
    3. the CCR clears the tested flag (`clr`). The younger EX1 update wins if it writes that flag too.
  - **RET/RTI:** `wait_r` stops fetching and makes decode ignore its input. The popped word reaches WB as RAM output, then `pcl_valid` makes it the fetch target and clears `wait_r`.
  - **CALL:** issues a push micro-op (`wsel = RET`, data = `id_npc`) and redirects fetch to `imm`.
- **Likely examiner questions + answers:**
  - *What is your static prediction?* Not-taken for JZ/JN/JC. Unconditional jumps are not "predicted": decode knows them, so they redirect immediately with 0 penalty.
  - *How many instructions do you flush on a taken conditional jump?* Two: the ones in ID and EX1. The fetch in the same cycle is already redirected to the target, so the penalty is 2 cycles (measured).
  - *What if a wrong-path instruction was HLT, RET or the first half of a SWAP?* Decode clears `halted`, `wait` and `phase` on a flush, so nothing from the wrong path survives (`control_corners.asm`).
  - *Why is JZ allowed right after the flag-producing instruction?* That instruction writes the CCR at the end of its EX1 cycle, exactly when the JZ moves from EX1 to EX2, so JZ reads the new value.
