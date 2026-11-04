# T-002: Repo skeleton, tooling and CI (uv, ruff, mypy, pytest, GHDL)

- **Status:** Done
- **Phase:** P1
- **Target:** W+0
- **Modules:** sim
- **Requirements:** REQ-A1, REQ-E6
- **Depends on:** T-001
- **Plan:** [PLAN-002](../implementationPlans/PLAN-002-repo-skeleton-ci.md)
- **TCs:** TC-102
- **ADRs:** ADR-002
- **Session:** [S002](../sessions/2026-11-04-S002-full-build-run.md)
- **Branch / PR:** `chore/T-002-repo-skeleton-ci` / PR #2

## Goal
A reproducible developer setup where `uv run poe check` runs exactly what CI runs, including GHDL.

## Scope
- In: pyproject (uv), `archp` package skeleton, poe tasks, ruff/mypy/pytest config, GHDL runner stub, docs link checker as a test, GitHub Actions CI, SG-001/SG-002.
- Out: Assembler/RTL content.

## Acceptance criteria
- [x] `uv run poe check` passes locally
- [x] CI green on the PR
- [x] SG-001 lets a fresh Ubuntu machine reach a green check

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
- 2026-11-04: first `poe check` failed on `ruff format` (one long call); formatted, then green: lint, mypy strict, 4 tests.

## Explain it (code-defense prep)
- **What changed:** The Python project (`archp`), the `poe` task runner, the GHDL driver `archp.ghdl`, a smoke testbench, a docs link test and GitHub Actions CI.
- **Why this design:** Neither ModelSim nor Quartus runs in CI. GHDL does, so every VHDL testbench becomes a pytest test, and one command (`uv run poe check`) runs exactly what CI runs. Each test gets its own GHDL work directory, so tests can run in parallel (`pytest -n auto`).
- **How it works:**
  - `ghdl.analyse(files, workdir)` runs `ghdl -a --std=93c` per file.
  - `ghdl.run(top, workdir, generics)` elaborates and runs with `-gNAME=value` and `--assert-level=error`, so any `severity error` assertion makes the exit code non-zero.
  - `test_ghdl_reports_assertion_failure` proves failures are not swallowed.
- **Likely examiner questions + answers:**
  - *Why GHDL and not ModelSim in CI?* ModelSim is licensed and GUI-oriented. GHDL is open source and scriptable. ModelSim is still used for the demo waveform (T-009).
  - *Why `--std=93c`?* Quartus 16.1's default VHDL version is 1993. Simulating in the same standard catches 2008-only constructs before Quartus does (ADR-002).
