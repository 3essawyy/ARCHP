# ADR-015: Read the register file in EX1 (no ID/EX1 operand registers, no RF bypass)

- **Status:** Accepted
- **Date:** 2026-11-04
- **Session:** S002
- **Related:** REQ-E7 (ALM ranking), ADR-004, ADR-014, T-011

## Context
The area proxy for T-011 (GHDL synth → Yosys `synth_intel_alm`, `tools/area.sh`) showed the decode-stage register read costs two things:
- **64 flip-flops:** operands A and B stored in ID/EX1;
- **~64 LUTs:** a write-back bypass mux inside the register file.

## Decision
- ID/EX1 carries only the source register numbers (`ra`, `rb`). The register file is read **combinationally at the start of EX1**, and its output feeds the forwarding muxes.
- The internal register-file bypass is removed. A value written by WB in the same cycle reaches EX1 through the existing WB→EX1 forwarding path; anything older is already in the register file.
- The load-use HDU stays in decode, unchanged.

## Alternatives considered
| Option | Why not |
|---|---|
| Keep the read in decode | +64 FF, +~64 LUT, no functional benefit |
| Register file in LUT-RAM (MLAB) | Can't be cleared by RESET. TA programs rely on registers being 0 after reset (last term's Branch.txt: `AND R5,R1,R5 #R5=0`). Rejected. |

## Consequences
- **Measured (proxy, static build):** 1,185 → 1,118 LUTs and 695 → 631 FF. All 735 tests pass in both predictor builds.
- **Timing:** the register-file read mux moves into the EX1 path. Timing isn't graded; area is.
- **Docs:** HLD §4.2/§4.3/§5 and the decode, register-file and EX1 LLDs must describe the read as happening in EX1 (pending T-011 docs).
