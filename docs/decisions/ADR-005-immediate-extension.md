# ADR-005: Immediate extension — LDM zero-extends, IADD and offsets sign-extend

- **Status:** Accepted
- **Date:** 2026-11-04
- **Session:** S001
- **Related:** REQ-I6, REQ-I10, REQ-I11

## Context
Immediates are 16 bits and registers 32 bits; the brief does not say signed or unsigned.

## Decision
- **LDM**: `R ← zext(Imm)` (literal reading of `Imm<15:0>`): `LDM R1,FFFF` → `0000FFFF`.
- **IADD**: `R ← Rsrc + sext(Imm)`, so `IADD R1,R1,FFFF` decrements. Carry = carry-out of the 32-bit addition.
- **LDD/STD offsets**: sign-extended. Only address bits [11:0] are used, and those are identical for both extensions.
- **Jump/CALL targets**: Imm[11:0].
- Hardware: one extender with a `imm_sext` control bit.

## Alternatives considered
| Option | Why not |
|---|---|
| Zero-extend all | IADD could not subtract |
| Sign-extend all | `LDM R,8000..FFFF` would produce negative values, which surprises test writers |

## Consequences
The assembler accepts negative immediates for IADD/offsets (encoded two's complement) and rejects them for LDM.
