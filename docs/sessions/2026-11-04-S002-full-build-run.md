# Session S002 — 2026-11-04 — Full-build run (T-002 onward)

- **Tasks touched:** T-002…T-005 (more appended as completed)
- **Branches / PRs:** one `<type>/T-NNN-slug` branch and one squash-merged PR per task

## Mode
After the S001 interview the user said "Execute": Claude builds T-002…T-013 in order, verifying each task by running it (user instruction: *always test your work and take feedback from that*).

## Done
- **T-002:** uv project `archp`, poe tasks, GHDL runner, smoke testbench (pass + forced fail), docs link test, CI (GHDL from apt), SG-001/SG-002. Feedback: the first `poe check` failed on formatting; fixed. PR #2.

- **T-003:** `archp.isa` + two-pass assembler + `archp asm` (.mem/.mif/.lst), SG-003, 68 tests. Feedback from tests: lone-label data words fixed; a TA typo (`IADD R1,R2,R3` in last term's Branch.txt) is now reported clearly. Carry conflict found (see Decisions). PR #3.
- **T-004:** golden ISA model, `archp golden`, 7 base programs with hand-computed expectations (all matched on the first run), 103 tests. PR #4.
- **T-005:** `archp_pkg`, ALU, CCR, register file, unified memory, unit benches (ALU vs golden on ~4.5k vectors). Each bench was mutation-checked; `ghdl --synth` infers the 4096 x 32 RAM, with no latches. 113 tests. PR #5.

## Decisions (with ADR links)
- SUB/CMP carry: the user ruled "brief silent → follow last term's implementation" = borrow. Evidence and a one-constant switch were added to [ADR-006](../decisions/ADR-006-flag-semantics.md).

## Open items / blockers
- None.

## Next steps (in order)
1. T-006 pipeline core + RTL test harness.

## Notes for next session
- GHDL 4.1 mcode from Ubuntu apt; `uv sync` downloads Python 3.12.
