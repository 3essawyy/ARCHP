# SG-005: Quartus 16.1 compile and Flow Summary

- **Audience:** developer | examiner (ranking evidence)
- **Last verified:** 2026-11-04. `ghdl --synth` of `processor_top` passes in both builds (no latches, 4096 x 32 RAM inferred) and the `.qsf` files are checked by `tests/test_quartus.py`. **The Quartus compile itself must be run by the team** (TC-212).

## Prerequisites
- Quartus Prime **Lite** Edition **16.1** (16.1.0.196) with **Cyclone V** device support (Windows or Linux).
- The repository checked out (Python is not needed for this guide).

## Steps
1. Open `quartus/archp.qpf` (*File → Open Project*).
2. The revision **`archp`** is the **ranked static-prediction build** (`G_DYNAMIC_BP = false`). Check it is selected in the toolbar revision box.
3. *Processing → Start Compilation* (Ctrl+L). **Do not change any setting**: the brief requires default compiler settings, and the `.qsf` contains only the device, the top level and the file list.
4. When it finishes, open *Compilation Report → Flow Summary* and take a screenshot. Save it as `docs/reports/flow-summary-static.png`. Record these in [reports/README](../reports/README.md):
   - Logic utilization (in ALMs);
   - Total registers;
   - **Total block memory bits**, which must be **131,072** (4096 x 32 in M10K);
   - Total pins (67 expected: 32 + 32 + clk + reset + intr).
5. Bonus build: switch the revision to **`archp_dynamic`** (it sets `G_DYNAMIC_BP = true`), compile again, and save `flow-summary-dynamic.png`.
6. The programming file `output_files/archp.sof` is produced by the Assembler step (REQ-E3).

## Verify it worked
- The Flow Summary shows *Successful*, a `.sof` exists, and block memory bits = 131,072.
- Analysis & Synthesis messages contain no "inferred latch" warning.

## Troubleshooting
| Symptom | Cause | Fix |
|---|---|---|
| Total block memory bits = 0 | RAM not inferred (e.g. the memory file was edited) | Keep `unified_memory.vhd` in the registered-address template; check the synthesis messages for "inferred RAM" |
| Warnings about unassigned pins / no SDC clock | No pin or timing constraints (default settings) | Expected; does not affect ALMs or registers |
| `Error (10500)` VHDL syntax | File compiled as VHDL-2008 by a changed setting | Keep the default VHDL input version (1993) |
| Very small ALM count | Logic removed because outputs don't depend on it | `processor_top` must keep OUT.PORT connected (it is) |
