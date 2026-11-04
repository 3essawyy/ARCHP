# ADR-008: SWAP as two micro-ops through a single register-file write port

- **Status:** Accepted
- **Date:** 2026-11-04
- **Session:** S001
- **Related:** REQ-I4, REQ-E5 (structural hazards)

## Context
SWAP writes two registers. A second write port costs a second 32-bit write path into all 8 registers plus forwarding of two results per stage.

## Decision
- Encoding: `Rd = Rdst, Ra = Rsrc, Rb = Rdst`.
- **uop1:** `Rdst ← R[Ra]` (PASSA). Issued only when the replay fetch can happen in the same cycle, which guarantees uop2 follows immediately. The load-use check covers both sources up front.
- **uop2:** `Rsrc ← R[Rb]` (PASSB), write address = `Ra`. uop2 does **not** take forwarding from EX2 (uop1 is there and holds the *new* Rdst value). The older value comes from MEM/WB forwarding or the register file, which uop1 has not written yet.
- The swap counts as one retired instruction (the `retire` bit is on uop2).

## Alternatives considered
| Option | Why not |
|---|---|
| 2 write ports | Many more ALMs (2:1 mux on 256 register bits + double forwarding) |
| Temporary register for the old value | +32 FF and a mux input |
| Assembler expands SWAP into 2 instructions | Changes code layout and isn't a hardware solution |

## Consequences
SWAP costs 2 cycles; it is a documented structural hazard with its own TC.
