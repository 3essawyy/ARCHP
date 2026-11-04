# T-002: Repo skeleton, tooling and CI (uv, ruff, mypy, pytest, GHDL)

- **Status:** Todo
- **Phase:** P1
- **Target:** W+0
- **Modules:** sim
- **Requirements:** REQ-A1, REQ-E6
- **Depends on:** T-001
- **Plan:** PLAN-002 (written when the task starts)
- **TCs:** TC-102
- **ADRs:** ADR-002
- **Session:** —
- **Branch / PR:** `chore/T-002-repo-skeleton-ci` / PR —

## Goal
A reproducible developer setup where `uv run poe check` runs exactly what CI runs, including GHDL.

## Scope
- In: pyproject (uv), `archp` package skeleton, poe tasks, ruff/mypy/pytest config, GHDL runner stub, docs link checker as a test, GitHub Actions CI, SG-001/SG-002.
- Out: Assembler/RTL content.

## Acceptance criteria
- [ ] `uv run poe check` passes locally
- [ ] CI green on the PR
- [ ] SG-001 lets a fresh Ubuntu machine reach a green check

## Definition of Done
- [ ] Code + tests passing (CI green)
- [ ] Module LLD updated
- [ ] Explain it section complete
- [ ] TCs updated
- [ ] ADR (if decision made)
- [ ] SystemGuides (if setup/usage changed)
- [ ] Session log
- [ ] PR squash-merged

## Notes / log

## Explain it (code-defense prep)
- **What changed:**
- **Why this design:**
- **How it works (walkthrough with file/function references):**
- **Likely examiner questions + answers:**
