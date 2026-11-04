# ADR-004: Single-port unified M10K memory; MEM has priority; RAM output as IR; replay on stall

- **Status:** Accepted
- **Date:** 2026-11-04
- **Session:** S001
- **Related:** REQ-G2, REQ-G4, REQ-P2-7, REQ-E5 (structural hazards), T-005, T-006

## Context
One 4096 x 32 memory with synchronous read (data one cycle after the address) must serve both fetch and data accesses, and must be inferred as M10K block RAM.

## Decision
- **One single-port RAM**, written in the Intel-recommended inference style (address registered inside the RAM, write-enable, read data available the next cycle). 4096 x 32 maps to 16 M10K blocks.
- **Arbitration:** if the instruction in MEM reads or writes memory, it drives the address; fetch is blocked that cycle (structural-hazard stall). Otherwise the fetch unit drives the address.
- **IF/ID instruction register = RAM output.** The address is registered by the RAM, so the word appears during the next cycle, which is the decode cycle. A cycle in which the RAM served data marks decode invalid (`fv = 0`).
- **Stall by replay:** when decode cannot accept or consume its instruction (load-use stall, multi-micro-op instruction), the fetch address that cycle is `id_pc`, so the same instruction is presented again next cycle. No 32-bit hold register is needed.

## Alternatives considered
| Option | Why not |
|---|---|
| True dual-port RAM (fetch + data) | User choice: the structural hazard must be visibly handled; same bit count either way |
| Separate 32-bit IR register after the RAM | +32 FF and effectively a 7th stage (an extra cycle of latency on every redirect) |
| Hold register for stalls | +32 FF + 32 mux bits; replay costs only a 12-bit address mux input |

## Consequences
- A replay can coincide with a MEM access; the replay then simply happens one cycle later (PC keeps `id_pc`).
- Back-to-back memory instructions starve fetch for those cycles; measured in TC-2xx program cycle counts.
