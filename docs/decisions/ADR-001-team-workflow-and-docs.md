# ADR-001: Team workflow and documentation structure

- **Status:** Accepted
- **Date:** 2026-11-04
- **Session:** S001
- **Related:** REQ-E8, all tasks

## Context
Team of 4; individual grades can differ, so every member must be able to defend the parts they own. Claude does the planning, implementation and testing. The team already uses this documentation scheme on GATP and wants the same here.

## Decision
- Claude implements everything. **No PR review**; Claude self-merges.
- Git: one branch per task (`<type>/T-NNN-slug`) → PR → **squash merge** to `main`; tags `phase1`, `phase2` at submission.
- Work is owned **by module** (see [modules/README](../modules/README.md)); owners prepare for the defense with the task docs' **Explain it** sections.
- Docs live in the repo under `/docs`, mirroring GATP: `architecture/`, `modules/<name>/`, `decisions/`, `implementationPlans/`, `tasks/`, `TCs/`, `SystemGuides/`, `RefrenceDocs/`, `sessions/`, plus `reports/` for the two submission reports.
- `docs/tasks/` markdown is the **single source of truth** for task status.
- Every task is verified by running something (tests, simulations, link check) before it is merged; results are recorded in the task and TCs.

## Alternatives considered
| Option | Why not |
|---|---|
| Everything on one long-lived branch | Hard to review and to explain per task; user chose per-task PRs |
| GitHub Issues as status source | Markdown keeps status readable in every session |
| Docs outside the repo | Drifts from code |

## Consequences
- Task docs carry the knowledge transfer (Explain it is mandatory).
- Session logs are the handoff between chats.
