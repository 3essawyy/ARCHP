# T-008: Interrupts, INT/RTI, reset boot, HLT

- **Status:** Done
- **Phase:** P2
- **Target:** W+3
- **Modules:** interrupts, decode, fetch
- **Requirements:** REQ-G5…G7, REQ-I1, REQ-I14
- **Depends on:** T-007
- **Plan:** [PLAN-008](../implementationPlans/PLAN-008-interrupts-reset-hlt.md)
- **TCs:** TC-207, TC-208
- **ADRs:** ADR-007, ADR-010
- **Session:** [S002](../sessions/2026-11-04-S002-full-build-run.md)
- **Branch / PR:** `feat/T-008-interrupts-reset-hlt` / PR #8

## Goal
Complete ISA: interrupts with corner cases, software INT, RTI, reset vector, HLT.

## Scope
- In: INTR edge latch, injection, micro-ops, context word, boot sequence, halted state; interrupt programs with pulses on branch/stall/load/CALL/RET corners.
- Out: Bonus predictor.

## Acceptance criteria
- [x] Interrupt sweep (pulse at every cycle of a branchy program) passes RTL == golden
- [x] Reset vector and HLT programs pass

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
- **Results:**
  - `int_sw.asm` and `interrupt.asm` give RTL == golden.
  - **Sweep:** one INTR pulse at every cycle 1…124 of `interrupt.asm`, landing on branches/flushes, load stalls, CALL/RET waits and memory conflicts. All 124 runs match the golden model, and each pulse before HLT is taken exactly once.
  - Held-high INTR gives exactly one interrupt. An interrupt after HLT is ignored.
  - 30 random programs with branches, CALL/RET, `INT 0/1` and 3 INTR pulses each all match.
- **Feedback (assumption corrected):** `test_back_to_back_pulses_nest` first assumed that two pulses 2 cycles apart give 2 interrupts. Measured: edges 2 cycles apart merge into one (the 1-bit request is still pending, not yet acknowledged); ≥ 3 cycles apart, both are served (nested). Merging is the standard behaviour of an edge-triggered request latch and the brief doesn't specify queuing, so it is **documented in ADR-007** and pinned by `test_edges_before_acknowledge_merge`.
- **Mutation checks** (all caught):

| Mutation | Failing tests |
|---|---|
| Acknowledge at injection (request lost on a flush) | 2 |
| Interrupt returns to PC+1 | 107 |
| Flush keeps `hw_phase` | 1 |
| RTI doesn't restore flags | 5 |
| Flags not saved in the context word | 15 |
| Level-sensitive INTR | 1 |
| Injection inside a SWAP/INT sequence | 2 |

- **Measured:** `INT 0` + `RTI` = 9 cycles over two NOPs (entry 5 + RTI 4), as in HLD §6.3. Pinned in `tests/test_timing.py`.

## Explain it (code-defense prep)
- **What changed:**
  - **Core:** the INTR rising-edge detector and the `int_pending` latch (acknowledged in EX2).
  - **Decode:** the sequencer gains the INT micro-ops (push `{CNZ, PC+1}`, then a vector read of `2+index`), hardware-interrupt injection (push `{CNZ, PC_of_instruction_in_ID}`, then a vector read of 1) and `hw_phase`.
  - **WB:** RTI restores the CCR from the popped word.
- **Why this design:**
  - **Reuse:** interrupts reuse the datapath that already exists (push with `wsel = CTX`, and a "load PC from memory" micro-op exactly like RET), so there is no separate interrupt FSM driving the memory.
  - **Precise interrupts:** injection happens in decode, so every older instruction completes normally ("finishes the instructions already in the pipeline"), and the replaced instruction is the return address.
  - **Never lost:** the request stays pending until the push reaches EX2, which can't be flushed. A wrong-path injection is simply redone on the right path.
- **How it works:**
  1. INTR rises → `int_pending = 1`.
  2. The next cycle with a valid instruction I in decode (not inside a SWAP/INT, not waiting, not halted) runs `inject`:
     - the control unit row `hw=1, phase=0` gives a push micro-op with `ret_pc = id_pc`;
     - `replay` re-presents I and `hw_phase ← 1`.
  3. Next valid cycle: row `hw=1, phase=1` gives the vector micro-op (ALU PASSB of imm = 1 → address 1; `pc_load`); `wait` is set.
  4. The push reaches EX2: its store word is `{CCR, 0…, ret_pc}`, and `int_pending` is cleared.
  5. The vector micro-op reaches WB: `pc_load` makes M[1] the fetch target and clears `wait`.
  6. RTI later pops the word. WB loads PC from bits 11:0 and the CCR from bits 31:29.
  - **INT n** is the same sequence with `ret_pc = PC+1` and vector `2+n` (= `"0…01" & instr(0)`).
- **Likely examiner questions + answers:**
  - *What exactly is pushed on an interrupt?* One word: C, N, Z in bits 31:29 and the address of the first instruction that has not executed in bits 11:0.
  - *What if the interrupt arrives while a branch is being resolved?* If the instruction we replaced was on the wrong path, the branch flushes our micro-ops too. `int_pending` is still set (only EX2 acknowledges it), so the interrupt is injected again on the correct path. The cycle sweep proves it at every position.
  - *Why not drain the pipeline and then run a hardware sequence?* That would need a second controller for the memory port and PC. Injection reuses push and the RET-style PC load and gives the same architectural result.
  - *What if INTR stays high?* Only the rising edge counts, so one interrupt (tested).
  - *What happens on an interrupt after HLT?* It is ignored until reset (ADR-010; tested).
