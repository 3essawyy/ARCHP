# T-006: Pipeline core: stages, pipeline registers, forwarding, load-use, structural hazards, SWAP + RTL test harness

- **Status:** Done
- **Phase:** P2
- **Target:** W+2
- **Modules:** fetch, decode, pipeline, ex1, ex2, mem-wb, hazards, sim
- **Requirements:** REQ-G1, REQ-P2-1, REQ-P2-2, REQ-E5
- **Depends on:** T-004, T-005
- **Plan:** [PLAN-006](../implementationPlans/PLAN-006-pipeline-core.md)
- **TCs:** TC-201…TC-205
- **ADRs:** ADR-004, ADR-008, ADR-013, ADR-014
- **Session:** [S002](../sessions/2026-11-04-S002-full-build-run.md)
- **Branch / PR:** `feat/T-006-pipeline-core` / PR #6

## Goal
A working 6-stage core for all non-control instructions, verified against the golden model.

## Scope
- In: fetch unit, decode stage + control unit, pipeline registers, EX1/EX2, MEM/WB, forwarding unit, HDU, memory arbitration, SWAP micro-ops, `processor_core`, `tb_processor`, `archp.ghdl`/`archp.compare`, CLI `archp sim/check`.
- Out: Branches, interrupts (T-007, T-008).

## Acceptance criteria
- [x] One/two-operand and memory programs: RTL == golden
- [x] Forwarding at distances 1–4 and load-use 1–3 covered
- [x] Memory-conflict and SWAP programs pass

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
- **Feedback 1 (tooling):** the first RTL runs from Python failed inside `textio`, while running GHDL by hand worked. Root cause: a separate `ghdl -e` step evaluated the testbench's file-loading constants with the *default* generics. Fix: one `--elab-run` call with the real generics, plus a subprocess timeout so a stuck simulation can't hang CI.
- **Feedback 2 (build order):** analysing files alphabetically failed (`ex1_stage` before `forwarding_unit`). The runner now uses GHDL import + make, which resolves dependencies.
- **Results:**
  - The first RTL run of every non-control program matched the golden model.
  - 40 random hazard-dense programs (`archp.fuzz`) match too.
  - Six **mutations** of the hazard logic were each caught by 14–44 failing tests:
    - no EX2 forwarding;
    - no WB forwarding;
    - no load-use check;
    - SWAP uop2 allowed to take EX2 forwarding;
    - no register-file bypass;
    - store data taken from the immediate path.
- **Feedback 3 (timing claims):** the first penalty measurement looked wrong (load-use 3 cycles). The cause was the test programs: HLT stopped fetching before the memory conflict appeared. With trailing NOPs the penalties match HLD §6 exactly, and `tests/test_timing.py` now pins them: load-use 2/1/0, ALU RAW 0, memory op 1, SWAP 1.
- Control-flow programs are strict-xfail until T-007/T-008.

## Explain it (code-defense prep)
- **What changed:** The complete 6-stage core for all non-control instructions, plus reset boot and HLT:
  - `fetch_unit`, `decode_stage` (+ `control_unit`), the four pipeline registers, `ex1_stage` (+ `forwarding_unit`, `alu`), `ex2_stage` (SP, address, store data), MEM arbitration and WB in `processor_core`;
  - the system testbench `tb_processor`;
  - `archp.sim` (run + compare) and `archp.fuzz`;
  - the CLI commands `archp sim` and `archp check`.
- **Why this design:**
  - **Structural hazard:** a single-port memory with MEM priority, and fetch simply loses that cycle.
  - **No IF/ID instruction register:** the RAM output *is* the IR, and stalls re-fetch the same address ("replay").
  - **Stalls end at decode:** they never propagate past ID, so EX1…WB always advance and their registers need no enable.
  - **Load data in WB:** with a synchronous RAM, load data exists only in WB, which fixes the load-use distances.
- **How it works (one instruction's life):**
  - **Fetch, cycle t:** the fetch unit puts `target` on the RAM address if MEM doesn't need it (`fetch_en`), sets `PC ← target+1`, `fv ← 1`, `id_pc ← target`.
  - **Decode, cycle t+1:** the RAM output is decoded by `control_unit`. The register file is read (with the WB bypass). The HDU checks the sources against loads in EX1/EX2: on a hit it sends a bubble and `replay` makes fetch re-read `id_pc`. SWAP issues uop1 only if the replay fetch can happen in the same cycle, so uop2 follows immediately.
  - **EX1, cycle t+2:** `forwarding_unit` picks register / EX2 / MEM / WB per operand (youngest first). The B input is the register or the extended immediate. The ALU computes, and the flags go to the CCR (gated by `flags_we` and `flush`).
  - **EX2, cycle t+3:** push → address = SP, SP−1; pop → address = SP+1, SP+1; otherwise address = ALU result. The data field carries the store word for writes and the ALU result for everything else.
  - **MEM, cycle t+4:** if it reads or writes, it takes the RAM port.
  - **WB, cycle t+5:** the register is written with the RAM output (loads) or the data field; OUT.PORT is updated.
  - **Boot:** reset → `boot` cycle reads M[0] → `bootq` cycle loads PC from the RAM output.
  - **HLT:** sets `halted`, which blocks fetch. The HLT micro-op itself retires, and older instructions drain.
- **Likely examiner questions + answers:**
  - *Where is your IF/ID register?* For the instruction word it is the M10K's address register. The RAM output during the decode cycle is the instruction fetched in the previous cycle. `fv` and `id_pc` are the small IF/ID side register in `fetch_unit`.
  - *What happens when LDD is followed by an instruction that uses the loaded register?* The data is only on the RAM output in WB. The HDU in decode stalls the consumer for 2 cycles (1 if one instruction sits between), then WB-to-EX1 forwarding delivers the value. Measured in `tests/test_timing.py`.
  - *How is the memory structural hazard solved?* MEM has priority (`mem_busy`). Fetch is blocked that cycle, PC keeps the target, and decode sees `fv = 0`, a bubble. Cost: one cycle per memory instruction (measured).
  - *Why can't SWAP's second micro-op use EX2 forwarding?* EX2 holds the first micro-op, which carries the new value of Rdst. The second micro-op needs the old one, which is still in older stages or the register file (`forwarding_unit`, `swap2`).
  - *How do you know forwarding is correct?* Hand-written distance tests plus 40 random hazard-dense programs compared word-for-word with the golden model. Deliberately breaking each forwarding path makes dozens of these tests fail.
