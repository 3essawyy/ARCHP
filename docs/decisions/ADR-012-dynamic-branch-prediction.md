# ADR-012: Bonus — 2-bit dynamic predictor with a BTB in fetch, behind `G_DYNAMIC_BP`

- **Status:** Accepted
- **Date:** 2026-11-04
- **Session:** S001
- **Related:** REQ-E5 (bonus), REQ-E7, T-010

## Context
The bonus asks for 2-bit dynamic prediction with **address calculation in fetch**. The predictor must be disable-able by a VHDL generic/constant, both builds must pass every test, and only the static build is ranked.

## Decision
- **Generic `G_DYNAMIC_BP : boolean`** on the core and top (default `false` = ranked static build). With `false` the predictor is not generated (`if … generate`), and the prediction bit is constant 0 so its logic is removed.
- **BTB in fetch:** 8 entries, direct-mapped on `pc[2:0]`. Each entry holds valid, tag `pc[11:3]`, target 12 bit and a 2-bit saturating counter. In the fetch cycle, a hit with counter ≥ 2 makes `PC ← BTB target` (the address is calculated in fetch).
- **Resolution in EX2:** `mispredict = taken xor predicted`. The redirect goes to `imm` if taken, else to `npc` (carried in `ret_pc`). The counter is updated and the entry allocated on a taken branch.
- In the dynamic build the fetch unit keeps a real `id_npc` register (in the static build `id_npc = PC`).

## Alternatives considered
| Option | Why not |
|---|---|
| Counter table only, target from the instruction in decode | Address computed in decode, not fetch; doesn't match the bonus wording |
| Global history (gshare) | Not required; more area |

## Consequences
CI runs every program in both modes.
