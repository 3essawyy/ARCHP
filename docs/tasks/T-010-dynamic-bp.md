# T-010: Bonus: 2-bit dynamic branch predictor with BTB in fetch

- **Status:** Done
- **Phase:** Bonus
- **Target:** W+4
- **Modules:** predictor, fetch, ex2
- **Requirements:** REQ-E5 (bonus), REQ-E7
- **Depends on:** T-008
- **Plan:** [PLAN-010](../implementationPlans/PLAN-010-dynamic-bp.md)
- **TCs:** TC-210
- **ADRs:** ADR-012
- **Session:** [S002](../sessions/2026-11-04-S002-full-build-run.md)
- **Branch / PR:** `feat/T-010-dynamic-bp` / PR #10

## Goal
Bonus marks without risking the ranked static build.

## Scope
- In: `btb.vhd`, `G_DYNAMIC_BP` generic, EX2 mispredict both directions, CI matrix both builds.
- Out: —

## Acceptance criteria
- [x] All programs pass with G_DYNAMIC_BP = true and false
- [x] Loop program shows fewer cycles with the predictor

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
- **Results:** every program, all fuzz families and the interrupt sweep now run in **both** builds (`G_DYNAMIC_BP = false/true`) and match the golden model.
- **Static build unchanged:** its cycle counts are identical to T-008 (branch 54, call_ret 49, interrupt 131), as they should be for the ranked build.
- **Loop speed-up:** `loop.asm` drops from 170 to 112 cycles with the predictor. That is exactly the predicted saving: 31 taken jumps × 2 − 2 mispredicts × 2 = 58 cycles. Pinned by `test_dynamic_predictor_speeds_up_loops`.
- **Feedback 1 (coverage gap):** the random programs only branched forward, so the BTB rarely saw a branch twice. The generator gained counted backward loops (`loops=True`), used in program and interrupt fuzzing.
- **Feedback 2 (an unreachable path):** the decode fix for a stale BTB hit (a non-branch predicted taken) was unreachable by any program. Added `smc_btb.asm` (self-modifying code); without the fix the dynamic build fails it.
- **Mutation checks:**

| Mutation | Failing tests |
|---|---|
| BTB prediction unused | 72 |
| EX2 ignores the prediction | 72 |
| Dynamic `npc = PC` | 73 |
| No stale-hit fix | 1 (`smc_btb`) |
| Allocate as weakly not-taken | 1 (speed-up test) |

## Explain it (code-defense prep)
- **What changed:**
  - `btb.vhd`: 8-entry direct-mapped BTB, each entry holding valid, a 9-bit tag, a 12-bit target and a 2-bit counter.
  - `fetch_unit`: BTB lookup and `next_pc` selection under `G_DYNAMIC_BP`, plus real `id_npc`/`id_pred` registers in that build.
  - `decode_stage`: passes `pred` on conditional jumps; redirects to `npc` when a non-branch was predicted taken.
  - `ex2_stage`: outputs for the predictor update (`bp_valid`, `bp_taken`).
  - Program `loop.asm`; both-mode tests.
- **Why this design:**
  - **Address calculation in fetch, as the bonus asks:** the BTB supplies the next PC in the same cycle the branch is fetched, so a correctly predicted taken jump costs 0 cycles instead of 2.
  - **No extra adder:** keying by `branch address + 1` uses `target_inc`, already computed in fetch, and `ret_pc`, already carried to EX2.
  - **Static build untouched:** with `G_DYNAMIC_BP = false` nothing is generated, `pred` is the constant 0, and EX2's `taken xor pred` reduces to `taken`. The ranked build is the same hardware as before.
- **How it works:**
  1. **Fetch:** `lk_npc = target+1` indexes the entry `npc[2:0]`. A tag match with counter MSB = 1 sets `PC ← entry.target`, and `pred_r ← 1` travels with the instruction.
  2. **Decode:** for JZ/JN/JC, `ctrl.pred ← id_pred`.
  3. **EX2:**
     - `redirect = taken xor pred`; the target is `imm` if taken, else `ret_pc` (= npc).
     - Update the entry: counter ±1 (saturating) and refresh the target. On a miss, allocate only when taken, as "10" (weakly taken).
- **Likely examiner questions + answers:**
  - *How do you disable the predictor for the ranking?* With the generic `G_DYNAMIC_BP` on `processor_core`/`processor_top` (default `false`). Both values pass every test in CI.
  - *Why index with PC+1?* That value already exists in fetch (`target+1`) and in EX2 (`ret_pc`). Indexing with the PC itself would need a decrement in EX2 or another 12-bit register in the pipeline.
  - *What happens on a 2-bit counter mispredict?* EX2 flushes ID and EX1 (2 cycles) and moves the counter one step. A loop costs one mispredict at the start and one at the exit (measured: 58 of 62 penalty cycles saved on a 32-iteration loop).
  - *What if the code changes under the BTB?* Decode checks that a predicted-taken instruction really is a conditional jump. If not, it redirects to `npc` (`smc_btb.asm`).
