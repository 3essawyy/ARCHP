# SG-002: Developer workflow

- **Audience:** developer
- **Last verified:** 2026-11-04 at the T-002 commit

## Prerequisites
[SG-001](SG-001-setup-and-checks.md) done.

## Steps
1. Read the newest session log in [docs/sessions/](../sessions/README.md) and the task in [docs/tasks/](../tasks/README.md).
2. Branch from `main`: `git checkout -b feat/T-NNN-short-slug`.
3. Write or update `docs/implementationPlans/PLAN-NNN-*.md` for non-trivial work.
4. Implement. Run the checks often:
   - `uv run poe check`: lint, types and all tests, the same as CI.
   - `uv run poe fmt`: auto-format Python.
   - `uv run pytest tests/test_x.py -k name`: run one test.
5. Update docs per the Definition of Done in [CLAUDE.md](../../CLAUDE.md), commit as `T-NNN: summary`, push, open a PR, squash-merge once CI is green.

## Repository layout
```
rtl/          synthesizable VHDL-93 (pkg, memory, fetch, decode, execute, pipeline, core, top)
tb/           testbenches (tb_processor.vhd, unit/)
src/archp/    Python: isa, assembler, golden model, ghdl runner, compare, cli
tests/        pytest: Python unit tests, GHDL unit benches, RTL-vs-golden programs, docs links
programs/     test programs (.asm) with #! directives
sim/modelsim/ do-files for the demo waveform
quartus/      Quartus Prime 16.1 project
docs/         all documentation
```

## How VHDL is tested
`archp.ghdl` analyses the files with `--std=93c` into a temporary work directory per test, elaborates the testbench and runs it with `-g` generics. Self-checking testbenches use `assert … severity error`; the run fails on any error and pytest shows the GHDL output.

## Verify it worked
CI on the PR shows the `check` job green.

## Troubleshooting
| Symptom | Cause | Fix |
|---|---|---|
| `ruff format --check` fails | Unformatted Python | `uv run poe fmt` |
| `test_no_broken_relative_links` fails | A Markdown link points to a missing file | Fix the link or create the file |
