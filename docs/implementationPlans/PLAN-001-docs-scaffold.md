# PLAN-001: Docs scaffold (for T-001)

- **Task:** [T-001](../tasks/T-001-docs-scaffold.md)
- **Status:** Executed
- **Date:** 2026-11-04

## Approach
Mirror GATP's docs system (same folders, IDs, templates, Definition of Done), add `reports/` for submissions, and write down the whole design from the S001 interview before coding so every later task implements an agreed ADR.

## Steps
1. Bootstrap `main` (README stub, .gitignore) so task PRs have a base.
2. CLAUDE.md, README, docs index, templates copied from GATP (module template paths adapted to `rtl/` + `src/archp/`).
3. REQ extraction from the brief with interpretation links.
4. HLD: ISA/encoding, datapath, stages, pipeline registers, hazards, interrupts, verification, resources, layout.
5. ADR-001…014 from the interview + design work.
6. Task breakdown T-001…T-013, module LLD stubs, TC definitions, SG/PLAN/report/session indexes.
7. Verify: link check over all docs.

## Files to create/change
| Path | Change |
|---|---|
| `CLAUDE.md`, `README.md` | New |
| `docs/**` | New |

## Tests to add
| Test | Proves |
|---|---|
| Relative-link check (script now; becomes `tests/test_docs_links.py` in T-002) | No dangling cross-references |

## Risks / open questions
| Item | Mitigation / decision |
|---|---|
| Design details change during RTL work | ADRs are superseded, never edited away; HLD updated per task |

## Deviations (filled after execution)
None.
