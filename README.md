# ARCHP — Six-stage pipelined processor

Course project for **CMPS 301 Computer Architecture** (Cairo University, Fall 2026).

A 32-bit RISC-like processor with a **6-stage pipeline** (Fetch, Decode, Execute-1, Execute-2, Memory, Write-Back) and a **Von-Neumann** memory (one 4096 x 32 M10K RAM for program and data), with data forwarding, load-use and structural-hazard stalls, static branch prediction, interrupts and an optional 2-bit dynamic predictor (bonus).

| Phase | Due | Status |
|---|---|---|
| Phase 1 — Design (ISA, schematic, pipeline, hazards) | Week 11 | Planning |
| Phase 2 — VHDL implementation, assembler, simulation, Quartus | Week 13 | Planning |
| Bonus — 2-bit dynamic branch prediction (address calc in fetch) | Week 13 | Planned (ADR-012) |

## Stack (see [ADRs](docs/decisions/README.md))

- **RTL:** VHDL-93, Quartus Prime Lite 16.1, Cyclone V 5CSEMA5F31C6
- **Simulation:** GHDL (CI + local), ModelSim do-files for the demo waveform
- **Tooling:** Python 3.12 (uv): assembler, golden ISA model, GHDL runner; ruff + mypy strict + pytest; poethepoet tasks

## Documentation

All project knowledge lives in [`docs/`](docs/README.md). Start there.

- High-level design: [docs/architecture/HLD.md](docs/architecture/HLD.md)
- Modules: [docs/modules/](docs/modules/README.md)
- Task status (source of truth): [docs/tasks/README.md](docs/tasks/README.md)
- Latest session handoff: [docs/sessions/](docs/sessions/README.md)
