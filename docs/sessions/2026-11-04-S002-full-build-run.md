# Session S002 — 2026-11-04 — Full-build run (T-002 onward)

- **Tasks touched:** T-002 (more appended as completed)
- **Branches / PRs:** one `<type>/T-NNN-slug` branch and one squash-merged PR per task

## Mode
After the S001 interview the user said "Execute": Claude builds T-002…T-013 in order, verifying each task by running it (user instruction: *always test your work and take feedback from that*).

## Done
- **T-002:** uv project `archp`, poe tasks, GHDL runner, smoke testbench (pass + forced fail), docs link test, CI (GHDL from apt), SG-001/SG-002. Feedback: the first `poe check` failed on formatting; fixed. PR #2.

## Decisions (with ADR links)
- None new.

## Open items / blockers
- None.

## Next steps (in order)
1. T-003 ISA + assembler.

## Notes for next session
- GHDL 4.1 mcode from Ubuntu apt; `uv sync` downloads Python 3.12.
