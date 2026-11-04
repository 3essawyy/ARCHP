# PLAN-002: Repo skeleton, tooling and CI (for T-002)

- **Task:** [T-002](../tasks/T-002-repo-skeleton-ci.md)
- **Status:** Executed
- **Date:** 2026-11-04

## Approach
Reuse GATP's Python tooling (uv, ruff, mypy strict, pytest, poe) as agreed, and make GHDL part of the same `poe check` so VHDL testbenches are just pytest tests. CI installs GHDL from Ubuntu's apt (same 4.1 as local).

## Steps
1. `pyproject.toml` (package `archp` in `src/`, dev tools, poe tasks, ruff/mypy/pytest config, pytest-xdist for parallel sims).
2. `archp.ghdl`: analyse/elaborate/run with `--std=93c`, isolated work dir per call.
3. `tb/unit/tb_smoke.vhd` + tests proving pass *and* fail are detected.
4. `tests/test_docs_links.py`: the T-001 link check as a permanent test.
5. `.github/workflows/ci.yml`, SG-001, SG-002.

## Files to create/change
| Path | Change |
|---|---|
| `pyproject.toml`, `uv.lock`, `.python-version` | New |
| `src/archp/{__init__,ghdl,cli}.py` | New |
| `tests/*`, `tb/unit/tb_smoke.vhd` | New |
| `.github/workflows/ci.yml` | New |
| `docs/SystemGuides/SG-001…002` | New |

## Tests to add
| Test | Proves |
|---|---|
| `test_ghdl_smoke_passes` | GHDL toolchain analyses + runs VHDL-93 |
| `test_ghdl_reports_assertion_failure` | A failing assertion fails the test (no silent passes) |
| `test_no_broken_relative_links` | Docs cross-references stay valid |

## Risks / open questions
| Item | Mitigation / decision |
|---|---|
| GHDL version differences CI vs local | Both use Ubuntu 24.04 apt `ghdl` 4.1 |

## Deviations (filled after execution)
None.
