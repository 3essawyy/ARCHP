# Session S002 — 2026-11-04 — Full-build run (T-002 onward)

- **Tasks touched:** T-002…T-010 done, T-011 in progress
- **Branches / PRs:** one `<type>/T-NNN-slug` branch and one squash-merged PR per task

## Mode
After the S001 interview the user said "Execute": Claude builds T-002…T-013 in order, verifying each task by running it (user instruction: *always test your work and take feedback from that*).

## Done
- **T-002:** uv project `archp`, poe tasks, GHDL runner, smoke testbench (pass + forced fail), docs link test, CI (GHDL from apt), SG-001/SG-002. Feedback: the first `poe check` failed on formatting; fixed. PR #2.

- **T-003:** `archp.isa` + two-pass assembler + `archp asm` (.mem/.mif/.lst), SG-003, 68 tests. Feedback from tests: lone-label data words fixed; a TA typo (`IADD R1,R2,R3` in last term's Branch.txt) is now reported clearly. Carry conflict found (see Decisions). PR #3.
- **T-004:** golden ISA model, `archp golden`, 7 base programs with hand-computed expectations (all matched on the first run), 103 tests. PR #4.
- **T-005:** `archp_pkg`, ALU, CCR, register file, unified memory, unit benches (ALU vs golden on ~4.5k vectors). Each bench was mutation-checked; `ghdl --synth` infers the 4096 x 32 RAM, with no latches. 113 tests. PR #5.
- **T-006:**
  - Full 6-stage core for non-control instructions (fetch/replay, decode/HDU/SWAP/HLT, forwarding, EX2 stack unit, MEM arbitration, WB), `tb_processor`, `archp sim/check`, fuzzer.
  - Results: RTL == golden on all programs plus 40 random programs; 6 hazard mutations each caught; measured penalties match HLD §6. 180 tests (+3 strict-xfail for T-007/T-008). PR #6.
  - Tooling feedback fixed: `--elab-run` instead of `-e`, GHDL make for dependency order.
- **T-007:** branch unit, flush, JMP/CALL redirect, RET/RTI wait; wrong-path HLT/RET/SWAP undone on flush. RTL == golden on all branch programs plus 40 random branchy programs; 5 of 6 mutations caught (the 6th is equivalent); penalties 2/0/4 measured. 227 tests. PR #7.
- **T-008:**
  - Interrupt latch, injection, INT/RTI micro-ops; the ISA is now complete.
  - Results: 124-cycle interrupt sweep plus 30 random programs with interrupts match golden; 7/7 interrupt mutations caught.
  - Measured: INT+RTI = 9 cycles; edges < 3 cycles apart merge (documented in ADR-007).
  - 390 tests. PR #8.
- **T-009:** ModelSim `compile.do`/`run.do`/`wave.do`, `.in`/`.intr` stimulus files, SG-004. Do-file consistency tested (order mutation caught). PR #9.
- **T-010 (bonus):**
  - 8-entry BTB + 2-bit counters in fetch behind `G_DYNAMIC_BP`; every test runs in both builds (724+); loop 170 → 112 cycles (exactly as predicted).
  - Coverage gaps fixed: loop fuzzing, `smc_btb.asm`. 5/5 predictor mutations caught. PR #10.
- **T-011 (in progress, branch `feat/T-011-quartus-area`, pushed, not merged):**
  - **Done:**
    - `processor_top.vhd` (the brief's ports only);
    - `quartus/archp.qpf` with revisions `archp` (static, ranked) and `archp_dynamic` (`set_parameter G_DYNAMIC_BP true`), default settings only;
    - `tests/test_quartus.py`: the qsf file list, default settings only, `ghdl --synth` of both builds with no latch and the RAM inferred. A latch-injection mutation is caught.
    - `tools/area.sh`: an area proxy. GHDL synth → Verilog → native `yosys synth_intel_alm`; initial values are stripped so the RAM maps to 16 M10K. Takes ~20 s.
    - SG-005 Quartus guide.
  - **Area work (measured with the proxy):**

| Step | LUTs | FF |
|---|---|---|
| Baseline (static build) | 1,321 | 695 |
| + one shared barrel shifter (SHR = reverse(SHL(reverse A))) | 1,185 | 695 |
| + register read in EX1, no RF bypass (ADR-015) | 1,118 | 631 |

    - Tried and reverted: PASSA through the adder (1,120 LUTs, no gain).
    - Dynamic build: 1,292 LUT / 838 FF.
    - Per-block LUTs (static): EX1 649 (ALU 364), register file 202 (+256 FF), decode 134, EX2 129, fetch 51.
  - All 735 tests passed after these changes (both builds) before the container restart.
- **T-012 groundwork:**
  - `tools/gen_schematic.py`: one block/wire model → `docs/architecture/schematic.drawio` (editable) + `schematic.svg`.
  - Layout reviewed by rendering to PNG with Playwright. A first version had forwarding wires ending on the ALU and IN.PORT drawn coming from the RAM; both were fixed.
  - Not yet run inside the repo or committed as outputs.

## Decisions (with ADR links)
- [ADR-015](../decisions/ADR-015-register-read-in-ex1.md): register file read in EX1, no RF bypass (area); MLAB register file rejected (no reset).
- ADR-007 consequence added: back-to-back INTR edges closer than the acknowledge latency merge (measured, T-008).
- SUB/CMP carry: the user ruled "brief silent → follow last term's implementation" = borrow. Evidence and a one-constant switch were added to [ADR-006](../decisions/ADR-006-flag-semantics.md).

## Open items / blockers
- **Team (needs ModelSim/Quartus, which can't run in the cloud container):**
  - TC-213: run SG-004 once in ModelSim.
  - TC-212: compile `quartus/archp.qpf` (both revisions) per SG-005. Record ALMs, registers and block memory bits (must be 131,072). Save the Flow Summary screenshots in `docs/reports/`.
- Module owners still `TBD` ([modules/README](../modules/README.md)).
- **Known risk (ADR-006):** last term's TA comment expects SUB carry = "not borrow", while last term's implementation used borrow. User rule: follow the implementation (borrow). Flip `C_SUB_CARRY_IS_BORROW` + `golden.SUB_CARRY_IS_BORROW` if the TA disagrees.
- **Documented limitation (ADR-007):** INTR edges < 3 cycles apart merge into one interrupt.

## Next steps (in order)
1. **Finish T-011:**
   - After the restart, run `uv run poe check` first. If GHDL/Yosys are missing: `sudo apt-get install -y ghdl yosys`.
   - Update HLD §4.2/4.3/5/6.1 and the decode/register-file/EX1/hazards LLDs for ADR-015 (the read is in EX1; the bypass is gone; WB forwarding covers same-cycle writes).
   - Note the shared shifter in the EX1 LLD. Write PLAN-011, the T-011 notes and Explain it (incl. the area table above), and set TC-211 to Pass.
   - Add SG-005 and `tools/area.sh` to the docs indexes. Squash-merge the PR.
2. **T-012 Phase 1 pack:**
   - Run `uv run python tools/gen_schematic.py`. Update the schematic for ADR-015: the register file feeds EX1, and the ID/EX1 bar carries `ra`/`rb`, not A/B.
   - Write `docs/reports/phase1-report.md`: ISA format and opcode table, schematic, control-unit table (from `control_unit.vhd`), stages, pipeline registers with exact sizes (recount after ADR-015), hazards (forwarding, load-use, structural, static prediction) with the measured penalties.
   - Render to PDF. There is no LaTeX in the container; use pandoc → HTML → Chromium/Playwright `page.pdf()`. Record that as an ADR.
3. **T-013 Phase 2 pack:**
   - Report on the design changes since the Phase 1 design: ADR-015 and the shared shifter. If Phase 1 is submitted after T-011, say so.
   - The hazards table, the Flow Summary screenshots (team), final TC statuses. Tag `phase1`/`phase2` at real submission (team).
4. **Optional area ideas not yet tried** (measure each with `tools/area.sh`):
   - IN.PORT through the B mux instead of the ALU result mux;
   - narrowing `ret_pc`/`target` carried through EX1/EX2.

## Notes for next session
- **Git flow:** one branch + PR per task, squash-merge after CI is green (GitHub MCP tools). PRs #1–#10 are merged. T-011 is on `feat/T-011-quartus-area`, ahead of `main`, no PR yet.
- **Tests:** `uv run poe check` runs ~735 tests (~65 s, parallel). They cover:
  - program RTL==golden in both builds;
  - 40+40+40 random programs per build;
  - a 124-cycle interrupt sweep per build;
  - timing penalties, unit benches, do-file/qsf consistency, synthesis.
- **Debugging a program:** `uv run archp check programs/x.asm [--dynamic] [--wave x.ghw]`.
- **Every RTL change was mutation-checked** (the test suite must fail when the feature is broken). Keep doing that.
- GHDL 4.1 mcode from Ubuntu apt; `uv sync` downloads Python 3.12.
