# ADR-010: HLT stops fetching and drains; no clock gating

- **Status:** Accepted
- **Date:** 2026-11-04
- **Session:** S001
- **Related:** REQ-I1

## Context
"HLT freezes CPU (no clock input) until a reset". Gating the clock is bad FPGA practice (skew, timing analysis).

## Decision
When HLT is decoded, `halted` is set:
- PC stops and no further fetch happens (younger instructions are squashed).
- Instructions older than HLT complete (their register writes, stores and OUT happen).
- Interrupts are ignored until RESET.

The clock keeps running; the processor is architecturally frozen.

## Alternatives considered
| Option | Why not |
|---|---|
| Gate the clock | Unsafe on FPGA |
| Global enable freezes all stages immediately | Older in-flight instructions would never finish |

## Consequences
The testbench detects completion as `halted = 1` with an empty pipeline.
