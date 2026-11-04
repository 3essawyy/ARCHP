# ADR-009: 12-bit physical PC and SP with a 32-bit architectural view

- **Status:** Accepted
- **Date:** 2026-11-04
- **Session:** S001
- **Related:** REQ-G3, REQ-G4, REQ-E7 (ALM ranking)

## Context
The spec lists PC and SP as 32-bit, but the address space is 4K words; bits above 11 can never address anything.

## Decision
- PC, SP, every pipeline copy of a PC (`id_pc`, `ret_pc`, targets) and the memory address are **12 bits**.
- Debug/waveform signals `pc_view` and `sp_view` zero-extend them to 32 bits.
- Pushed return addresses are zero-extended. Loaded PCs (RET, RTI, vectors) use bits [11:0].
- SP wraps modulo 4096 (stack under/overflow is undefined behaviour, as in the brief).

## Alternatives considered
| Option | Why not |
|---|---|
| Full 32-bit PC/SP | ~40 more FF in PC/SP alone, ~100 across the pipeline, plus wider adders; no functional difference |

## Consequences
A program cannot observe the difference except through the upper bits of a popped return address, which are always 0 (CALL) or flags (INT, ADR-007).
