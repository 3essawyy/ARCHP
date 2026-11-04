# Module: mem-wb

- **Owner:** TBD
- **Status:** In progress (memory done in T-005; MEM/WB in T-006)
- **Code:** `rtl/memory/unified_memory.vhd`, core integration
- **Tasks:** T-005, T-006, T-008
- **ADRs:** ADR-004

## Responsibility
Unified memory (4096 x 32 single-port, M10K inference, file initialisation for simulation), MEM-stage port ownership, write-back (register write data select, OUT.PORT, PC load, RTI flag restore).

## Interfaces
| Direction | Interface | Contract |
|---|---|---|
| Provides | `unified_memory(G_INIT_FILE)(clk, we, addr, din) -> dout` | 4096 x 32, data one clock after the address; write on the rising edge |

## Data
16 x M10K (131,072 bits) expected in Quartus.

## Internal design
Intel single-port RAM template: `ram(addr) <= din when we`; `addr_reg <= addr`; `dout <= ram(addr_reg)`. The init function reads a hex file (one word per line, `@hex` = new address, `/` or `#` = comment) in simulation only (`synthesis translate_off`). GHDL synth reports a 4096 x 32 RAM.

## Validation and failure modes
| Failure | Detection | Behavior |
|---|---|---|

## Config
| Key | Default | Meaning |
|---|---|---|

## Tests
`test_memory` (TC-106).

## Known limitations
