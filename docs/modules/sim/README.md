# Module: sim

- **Owner:** TBD
- **Status:** In progress (T-002 runner; T-006 system TB, sim/compare, fuzz)
- **Code:** `tb/`, `src/archp/ghdl.py`, `src/archp/compare.py`, `src/archp/cli.py`, `sim/modelsim/`, `quartus/`, `.github/workflows/`
- **Tasks:** T-002, T-006, T-009, T-011
- **ADRs:** ADR-002, ADR-013

## Responsibility
Verification and tool flow: testbenches, GHDL runner, RTL-vs-golden comparison, CLI, ModelSim do-files, Quartus project, CI.

## Interfaces
| Direction | Interface | Contract |
|---|---|---|
| Provides | `tb_processor` generics `G_PROGRAM, G_INPUTS, G_INTR, G_DUMP, G_MAX_CYCLES, G_DYNAMIC_BP` | Dump: STATUS, CYCLES, RETIRED, PC, SP, FLAGS, R0–R7, OUT*, INT*, M (non-zero) |
| Provides | `archp.sim.build/run_rtl/golden_for/compare`, `archp.fuzz.generate` | |
| Provides | CLI `archp sim|check prog.asm [--dynamic] [--wave f.ghw]` | |

## Data
(filled when implemented)

## Internal design
- `archp.ghdl`: `analyse(files, workdir)`, `run(top, workdir, generics)` (VHDL-93, `--assert-level=error`), `rtl_files()` (dependency order: pkg, memory, decode, execute, pipeline, fetch, core, top).
- CI: `.github/workflows/ci.yml` installs GHDL from apt, `uv sync --locked`, then lint, types, tests.

- **Shadow memory:** the testbench keeps its own copy (program + every write seen on the memory port), so the final memory can be dumped without hierarchical references (VHDL-93).
- **IN.PORT:** advances on `dbg_in_rd`.
- **Interrupt log:** the retired count at each `dbg_hwint`.
- **Build reuse:** the RTL + TB are built once per pytest worker (`rtl_build` fixture) and each program runs with `--elab-run` and its own generics.

- **ModelSim:** `sim/modelsim/compile.do` (explicit order), `run.do <stem> [dynamic]`, `wave.do` (CLK, Reset, Interrupt, IN.port, OUT.port, PC, SP, Flags, R0–R7). [SG-004](../../SystemGuides/SG-004-modelsim-demo.md).

## Validation and failure modes
| Failure | Detection | Behavior |
|---|---|---|

## Config
| Key | Default | Meaning |
|---|---|---|

## Tests
`tests/test_modelsim.py` (do-file consistency, TC-213 automated part).
`tests/test_programs.py`, `tests/test_timing.py`.
- `tests/test_toolchain.py` (T-002): GHDL smoke pass + forced failure.
- `tests/test_docs_links.py`: relative Markdown links.

## Known limitations
