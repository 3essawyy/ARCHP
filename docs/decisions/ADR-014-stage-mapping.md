# ADR-014: Stage mapping — effective address in EX1's adder; EX2 forms the final address

- **Status:** Accepted
- **Date:** 2026-11-04
- **Session:** S001
- **Related:** REQ-G1

## Context
The brief lists "Execute-2: branch decision resolution, memory LDD/STD address calculation". Computing `Rsrc + offset` in EX2 needs a second adder and a second forwarded copy of the base register.

## Decision
- **EX1:** the ALU adds `Ra + sext(offset)` for LDD/STD with flag writes disabled (the same path as IADD). The base register is forwarded like any operand.
- **EX2:** the memory address calculation proper:
  - selects the address: effective address, SP (push) or SP+1 (pop);
  - computes `SP±1` and updates SP;
  - forms the store-data word.
- **EX2** also resolves JZ/JN/JC, as specified.

## Alternatives considered
| Option | Why not |
|---|---|
| Separate address adder in EX2 | A 12-bit adder and operand plumbing duplicating the ALU; hurts the ALM ranking |

## Consequences
The Phase-1 report states this mapping explicitly so the examiner sees where each part of "address calculation" happens.
