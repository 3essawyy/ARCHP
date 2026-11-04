# ADR-002: Toolchain — VHDL-93 RTL, GHDL in CI, ModelSim/Quartus locally, Python (uv) tools

- **Status:** Accepted
- **Date:** 2026-11-04
- **Session:** S001
- **Related:** REQ-E4, REQ-P2-1…3, T-002

## Context
The brief requires Quartus Prime Lite 16.1 with **default compiler settings** (VHDL input version defaults to VHDL-1993) and a ModelSim waveform. Neither tool can run in the cloud container or in GitHub Actions. We still want every change verified automatically.

## Decision
- **RTL language:** synthesizable **VHDL-93**, which is Quartus 16.1's default. No VHDL-2008 constructs (`process(all)`, `?=`, reading `out` ports…). Testbenches are also VHDL-93, so one GHDL library builds everything.
- **Simulation in CI and locally:** **GHDL** (`--std=93c`). A Python runner (`archp.ghdl`) compiles, elaborates and runs testbenches with generics.
- **Synthesis sanity in CI:** `ghdl --synth` on the Quartus top level catches latches, non-synthesizable code and multiple drivers before anyone opens Quartus.
- **Demo and grading tools (team, local):** ModelSim (do-files in `sim/modelsim/`) and Quartus 16.1 (`quartus/archp.qpf`). The Flow Summary is taken there.
- **Python tooling (same as GATP):** uv, ruff, mypy `--strict`, pytest, poethepoet. `uv run poe check` runs everything CI runs.

## Alternatives considered
| Option | Why not |
|---|---|
| VHDL-2008 | Not Quartus 16.1's default; partial support risks a compile failure at grading time |
| ModelSim only | Not automatable in CI; the team would verify by eye |
| Verilator / cocotb | Extra stack; GHDL + a Python golden model is enough |

## Consequences
- Combinational processes need complete sensitivity lists; code review plus `ghdl --synth` warnings guard this.
- The team must run Quartus once per milestone and record the numbers (SG-005).
