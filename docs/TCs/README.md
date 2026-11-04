# Acceptance Test Cases (for ARCHP)

These prove ARCHP meets the brief. Definitions: [phase1.md](phase1.md), [phase2.md](phase2.md). Template for long TCs: [_TEMPLATE.md](_TEMPLATE.md).

Update **Status** with date + commit whenever a TC is run. Automated TCs run in CI on every PR (`uv run poe check`).

## Traceability matrix

| Requirement / grading line | Marks | TCs | Tasks |
|---|---|---|---|
| REQ-P1-1…4 Phase 1 design | — | TC-101 | T-001, T-012 |
| Reproducible setup | — | TC-102 | T-002 |
| REQ-P2-3 Assembler | — | TC-103, TC-104 | T-003 |
| REQ-I* ISA semantics (reference) | — | TC-105 | T-004 |
| REQ-P2-1 Components | — | TC-106 | T-005 |
| REQ-E5 Instructions | 12 | TC-201, TC-202, TC-203, TC-206, TC-207, TC-208, TC-209 | T-006…T-008 |
| REQ-E5 Data hazards | 1 | TC-204 | T-006 |
| REQ-E5 Structural hazards | 1 | TC-205 | T-006 |
| REQ-E5 Control hazards | 1 | TC-206 | T-007 |
| REQ-E5 Bonus dynamic prediction | +2 | TC-210 | T-010 |
| REQ-E6 / REQ-A1 No latches, synthesizable | — | TC-211 | T-011 |
| REQ-E4 / REQ-E7 / REQ-P2-7 Quartus, M10K, ranking | 5 | TC-212 | T-011 |
| REQ-E2 / REQ-P2-2 Waveform via do-files | — | TC-213 | T-009 |
| REQ-P2-4…6 Phase 2 report | — | TC-214 | T-013 |

## Index

| ID | Title | Type | Status |
|---|---|---|---|
| TC-101 | Phase 1 design report covers every required element | Manual | Not run |
| TC-102 | Clean setup from SG-001; `poe check` green | Manual + CI | Partial: **Pass** in CI (ubuntu-24.04) 2026-11-04 (T-002); fresh-laptop run by team pending |
| TC-103 | Every instruction encodes per the ISA table | Automated | **Pass** 2026-11-04 (T-003) |
| TC-104 | Assembler accepts the TA program format and reports errors | Automated | **Pass** 2026-11-04 (T-003) |
| TC-105 | Golden model implements every ISA rule (ADR-005…010) | Automated | **Pass** 2026-11-04 (T-004) |
| TC-106 | Unit testbenches: ALU, register file, memory, CCR | Automated | **Pass** 2026-11-04 (T-005), mutation-checked |
| TC-201 | One-operand instructions: RTL == golden | Automated | **Pass** 2026-11-04 (T-006) |
| TC-202 | Two-operand instructions: RTL == golden | Automated | **Pass** 2026-11-04 (T-006) |
| TC-203 | Memory and stack instructions: RTL == golden | Automated | **Pass** 2026-11-04 (T-006) |
| TC-204 | Data hazards: forwarding distances 1–4, load-use 1–3, flags | Automated | **Pass** 2026-11-04 (T-006, flags→jump T-007) |
| TC-205 | Structural hazards: memory port conflicts, SWAP | Automated | **Pass** 2026-11-04 (T-006) |
| TC-206 | Control hazards: JZ/JN/JC taken/not, flag clear, JMP/CALL/RET | Automated | **Pass** 2026-11-04 (T-007) |
| TC-207 | INT/RTI and hardware interrupt incl. branch/stall corner cases | Automated | **Pass** 2026-11-04 (T-008): 124-cycle sweep, 30 random programs |
| TC-208 | Reset vector and HLT | Automated | **Pass** 2026-11-04 (T-006, T-008) |
| TC-209 | TA-style test programs (Branch/Memory/One/Two operand style) | Automated | Not run |
| TC-210 | Dynamic-predictor build passes every program | Automated | Not run |
| TC-211 | `ghdl --synth` of the top: synthesizable, no latches | Automated | Not run |
| TC-212 | Quartus 16.1 full compile: programming file, block memory bits = 131072, Flow Summary | Manual (team) | Not run |
| TC-213 | ModelSim waveform with the required signals only | Manual (team) | Automated part **Pass** 2026-11-04 (T-009); GUI run: team |
| TC-214 | Phase 2 report content | Manual | Not run |
