# Module: register-file

- **Owner:** TBD
- **Status:** Implemented (T-005)
- **Code:** `rtl/decode/register_file.vhd`
- **Tasks:** T-005
- **ADRs:** ADR-008

## Responsibility
8 x 32 general-purpose registers, two combinational read ports, one synchronous write port, write-back bypass, reset to 0.

## Interfaces
| Direction | Interface | Contract |
|---|---|---|
| Provides | `register_file(clk, rst, ra_addr, rb_addr, we, wa, wd) -> ra_data, rb_data, regs_out` | Combinational reads with WB bypass; write on the rising edge; sync reset to 0 |

## Data
R0–R7 exported as `regs_out` for the waveform.

## Internal design
`regs : reg_array_t` (8 x 32 FF). `ra_data <= wd when we and wa = ra_addr else regs(ra_addr)` (same for B).

## Validation and failure modes
| Failure | Detection | Behavior |
|---|---|---|

## Config
| Key | Default | Meaning |
|---|---|---|

## Tests
`tests/test_rtl_units.py::test_register_file` (TC-106).

## Known limitations
