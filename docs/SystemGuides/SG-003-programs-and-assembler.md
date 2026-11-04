# SG-003: Writing and assembling programs

- **Audience:** tester | developer | examiner
- **Last verified:** 2026-11-04 (cloud container) at the T-003 commit

## Prerequisites
[SG-001](SG-001-setup-and-checks.md).

## Program format (the TA format)
```
# comments start with # (or ;)
.ORG 0          # next item at address 0 (hex)
10              # a bare number = raw data word: M[0] = 0x10 (reset vector)
.ORG 10
start: IN R1    # labels end with ':'
       IADD R1, R1, 10      # numbers are HEX by default (0x10)
       LDD R2, 200(R1)      # memory operand offset(Rn)
       JZ start             # labels or numbers for targets
table: .WORD -1             # explicit data word (two's complement)
```
- Prefixes: `0x` (hex), `0d` (decimal), `0b` (binary); `-` for negative where signed.
- Vectors: M[0] reset, M[1] hardware interrupt, M[2]/M[3] `INT 0`/`INT 1`.
- Operand placement and opcodes: [HLD §3.2](../architecture/HLD.md#32-opcodes-and-operand-placement).

### Test directives (`#!` lines, used by `archp sim`/`check`)
| Directive | Meaning |
|---|---|
| `#! in: 30 50 FFFF` | Values (hex) returned by successive `IN` instructions |
| `#! intr: 40 95` | INTR.IN pulses at these clock cycles (decimal) |
| `#! expect: R1=30 SP=FFE Z=1 M[210]=5 OUT=30,50` | Final-state checks (hex) |
| `#! max_cycles: 5000` | Simulation budget (decimal) |

## Steps
1. Assemble:
   ```bash
   uv run archp asm programs/one_operand.asm
   ```
2. This writes `programs/one_operand.mem` (simulation), `.mif` (Quartus), `.lst` (listing: address, word, disassembly, source line), and `.in`/`.intr` (testbench stimuli from the `#!` lines; used by the ModelSim `run.do`, [SG-004](SG-004-modelsim-demo.md)).

## Simulating a program (GHDL)
- `uv run archp golden prog.asm`: golden model only (instant).
- `uv run archp sim prog.asm [--wave prog.ghw]`: RTL only; prints registers, cycles, OUT log. Open `.ghw` with GTKWave.
- `uv run archp check prog.asm`: RTL and golden, compared word for word, plus `#! expect` (prints `PASS`/`FAIL` and each difference).

## Verify it worked
The command prints `wrote …` three times and the word/instruction counts. Errors print `file:line: message` and exit with code 1.

## Troubleshooting
| Symptom | Cause | Fix |
|---|---|---|
| `expected a number or label, got register` | e.g. `IADD R1, R2, R3` (a typo in the source) | Use an immediate |
| `address 0x.. already used by line N` | Two `.ORG` blocks overlap | Move one block |
| `unsigned immediate … out of range` on LDM | LDM is zero-extended (ADR-005) | Use a value 0…FFFF |
