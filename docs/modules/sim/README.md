# Module: sim

- **Owner:** TBD
- **Status:** In progress (T-002: GHDL runner, CI)
- **Code:** `tb/`, `src/archp/ghdl.py`, `src/archp/compare.py`, `src/archp/cli.py`, `sim/modelsim/`, `quartus/`, `.github/workflows/`
- **Tasks:** T-002, T-006, T-009, T-011
- **ADRs:** ADR-002, ADR-013

## Responsibility
Verification and tool flow: testbenches, GHDL runner, RTL-vs-golden comparison, CLI, ModelSim do-files, Quartus project, CI.

## Interfaces
| Direction | Interface | Contract |
|---|---|---|
| Provides | | (filled when implemented) |
| Consumes | | |

## Data
(filled when implemented)

## Internal design
- `archp.ghdl`: `analyse(files, workdir)`, `run(top, workdir, generics)` (VHDL-93, `--assert-level=error`), `rtl_files()` (dependency order: pkg, memory, decode, execute, pipeline, fetch, core, top).
- CI: `.github/workflows/ci.yml` installs GHDL from apt, `uv sync --locked`, then lint, types, tests.

## Validation and failure modes
| Failure | Detection | Behavior |
|---|---|---|

## Config
| Key | Default | Meaning |
|---|---|---|

## Tests
- `tests/test_toolchain.py` (T-002): GHDL smoke pass + forced failure.
- `tests/test_docs_links.py`: relative Markdown links.

## Known limitations
