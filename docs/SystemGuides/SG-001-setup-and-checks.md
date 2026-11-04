# SG-001: Setup and checks

- **Audience:** developer | examiner
- **Last verified:** 2026-11-04 on Ubuntu 24.04 (cloud container) at the T-002 commit

## Prerequisites
- Linux (Ubuntu 22.04/24.04) or WSL2 on Windows.
- `git`, and `curl` for the uv installer.
- For the demo and grading only (not needed for `poe check`): ModelSim (Intel FPGA Starter Edition shipped with Quartus 16.1) and Quartus Prime Lite 16.1 with Cyclone V support. See SG-004 and SG-005.

## Steps
1. Install GHDL (the VHDL simulator used by the tests):
   ```bash
   sudo apt-get update && sudo apt-get install -y ghdl
   ```
2. Install uv (Python project manager):
   ```bash
   curl -LsSf https://astral.sh/uv/install.sh | sh
   ```
3. Clone and install the Python environment (uv downloads Python 3.12 if needed):
   ```bash
   git clone https://github.com/3essawyy/ARCHP.git && cd ARCHP && uv sync
   ```
4. Run everything CI runs:
   ```bash
   uv run poe check
   ```

## Verify it worked
`poe check` ends with `N passed` and no failures. `ghdl --version` prints GHDL 4.x.

## Troubleshooting
| Symptom | Cause | Fix |
|---|---|---|
| Tests marked `SKIPPED (ghdl not installed)` | GHDL not on PATH | Step 1 |
| `uv: command not found` | Shell not reloaded after installing uv | Open a new terminal or `source ~/.local/bin/env` |
