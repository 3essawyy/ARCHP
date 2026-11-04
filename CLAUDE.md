# Working agreement for Claude on ARCHP

Read this first in every session. It is the operating manual for whoever (Claude or a human) continues the work.

ARCHP is the CMPS 301 (Fall 2026) architecture project: a 6-stage pipelined, Von-Neumann, RISC-like processor in VHDL, plus its assembler, a Python reference (golden) model and the simulation/synthesis flow. Brief: [docs/RefrenceDocs/Architecture_Project_Fa26.pdf](docs/RefrenceDocs/Architecture_Project_Fa26.pdf).

## Roles
- Team of 4. Claude plans, implements and tests across all phases.
- No PR review. Claude opens and squash-merges its own PRs ([ADR-001](docs/decisions/ADR-001-team-workflow-and-docs.md)).
- Each module has a component owner (assigned at kickoff, recorded in [docs/modules/README.md](docs/modules/README.md)). Owners prepare for the code defense through the task docs ("Explain it").

## Session protocol
**Start of session**
1. Read the latest file in `docs/sessions/` (handoff + next steps).
2. Read `docs/tasks/README.md` (status = source of truth).
3. Read the task file, its PLAN, and the module docs it touches.

**During**
- One branch per task: `<type>/T-NNN-short-slug` (type = feat | fix | docs | chore | test).
- Write or update `docs/implementationPlans/PLAN-NNN-*.md` before coding non-trivial tasks.
- Record any new decision as an ADR in `docs/decisions/`.
- Keep the golden model and the RTL in lock-step: an ISA behaviour change touches `src/archp/golden.py`, the RTL, the ADR and the HLD in the same PR.

**End of session**
1. Update task status in `docs/tasks/README.md` and the task file.
2. Write `docs/sessions/YYYY-MM-DD-SNNN-slug.md` using the template (done, decisions, open items, next steps).
3. Push, open the PR, squash-merge to `main`.

## Definition of Done (every task)
- [ ] Code implemented; tests written and passing (`uv run poe check` locally, CI green)
- [ ] Module design doc (`docs/modules/<name>/README.md`) updated
- [ ] Task doc complete, including the **Explain it** section (what, why, how it works, likely examiner questions)
- [ ] Acceptance TCs in `docs/TCs/` updated (IDs + status)
- [ ] ADR added if a decision was made
- [ ] SystemGuides updated if setup or usage changed
- [ ] Session log written
- [ ] PR merged (squash) to `main`

## Conventions
- IDs: `T-NNN` task, `PLAN-NNN` plan (same number as its task), `ADR-NNN` decision, `TC-NNN` acceptance test case, `REQ-NN` requirement, `SG-NNN` system guide, `SNNN` session.
- Every docs folder has a `README.md` index. Add a row whenever you add a file.
- Cross-link by ID and relative link. Never duplicate content; link to it.
- Releases: tag `phase1` and `phase2` on `main` at submission.
- Commit messages: `T-NNN: imperative summary`.

## Non-negotiable project rules (from the brief)
- RTL is synthesizable **VHDL-93** (Quartus Prime Lite 16.1 default), targeting Cyclone V **5CSEMA5F31C6** with default compiler settings ([ADR-002](docs/decisions/ADR-002-toolchain.md)).
- The memory is **one** 4096 x 32 array, synchronous read, inferred as **M10K** block RAM ("Total block memory bits" must be non-zero).
- No inferred latches, no gated clocks, no `U`/floating inputs. Every register has a reset.
- Area matters (ALM ranking, static-prediction build): justify every added register or mux.
- The dynamic predictor must be switchable off with the generic `G_DYNAMIC_BP`; **both** builds must pass every test program.
- Never weaken a test or change expected behaviour to make a test pass; fix the RTL or the golden model and say which was wrong.
