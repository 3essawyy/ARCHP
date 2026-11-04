# T-001: Docs scaffold, requirements, HLD, ADRs, task breakdown

- **Status:** Done
- **Phase:** P1
- **Target:** W+0
- **Modules:** docs
- **Requirements:** REQ-G*, REQ-P1-*
- **Depends on:** —
- **Plan:** [PLAN-001](../implementationPlans/PLAN-001-docs-scaffold.md)
- **TCs:** TC-101 (partial)
- **ADRs:** ADR-001…ADR-014
- **Session:** [S001](../sessions/2026-11-04-S001-kickoff-design-interview.md)
- **Branch / PR:** `docs/T-001-docs-scaffold` / PR #1

## Goal
Mirror GATP's documentation system in ARCHP and capture the full design and every interview decision before any code is written.

## Scope
- In: CLAUDE.md, docs/ tree with indexes and templates, REQ extraction, HLD, ADR-001…014, task/TC/module breakdown, session S001.
- Out: Code.

## Acceptance criteria
- [x] Every docs folder has a README index
- [x] Every interview decision has an ADR
- [x] HLD covers ISA, datapath, stages, pipeline registers, hazards, interrupts, verification
- [x] All relative links resolve (link check)

## Definition of Done
- [x] Link check passes (no CI yet; T-002 adds it)
- [x] Module LLD updated
- [x] Explain it section complete
- [x] TCs updated
- [x] ADR (if decision made)
- [x] SystemGuides (if setup/usage changed)
- [x] Session log
- [x] PR squash-merged

## Notes / log
- 2026-11-04: link check found 14 links to plans that don't exist yet. Tasks now show `PLAN-NNN (written when the task starts)` until the plan exists; templates are excluded from the check.

## Explain it (code-defense prep)
- **What changed:** The repository's knowledge base: CLAUDE.md (operating manual), `docs/` with the GATP structure, the requirements extracted from the brief, the HLD and 14 ADRs.
- **Why this design:** Each team member is graded individually and must defend their module. Writing every decision down *with its alternatives* before coding lets owners explain "why", not just "what". Ambiguities in the brief (immediate extension, carry on SUB, SHR carry, flag save, HLT) are resolved once in ADRs, and both the golden model and the RTL follow them.
- **How it works:** REQ-* IDs (RefrenceDocs) → tasks (tasks/) → plans, module LLDs and TCs. ADRs constrain tasks. Session logs hand over between chats.
- **Likely examiner questions + answers:**
  - *Why one 32-bit word per instruction when the brief says some take two locations?* All fields (5+3+3+3+16 bits) fit in 32 bits, so a second word would only add fetch cycles and hardware (ADR-003).
  - *Why is the memory single-port?* The brief says one memory. Port contention is the structural hazard we handle by giving MEM priority and stalling fetch (ADR-004).
  - *Where are the flags saved on interrupt?* In bits 31:29 of the same stack word as the return PC, so it is one push and nesting works (ADR-007).
