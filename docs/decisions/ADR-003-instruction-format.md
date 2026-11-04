# ADR-003: One 32-bit word per instruction, fixed register-field positions

- **Status:** Accepted
- **Date:** 2026-11-04
- **Session:** S001
- **Related:** REQ-G8, REQ-P1-1, T-003

## Context
Memory words are 32 bits. Opcode (5 bits) + three 3-bit register fields + a 16-bit immediate = 30 bits, which fits in one word. The brief warns that "some instructions will occupy more than one memory location", which is true for 16-bit-word variants of this project but not needed with 32-bit words.

## Decision
- Every instruction is exactly **one 32-bit word**: `[31:27] opcode | [26:24] Rd (write port) | [23:21] Ra (read port A) | [20:18] Rb (read port B) | [17:16] 00 | [15:0] Imm/Offset/target/index`.
- The assembler places each operand in the field of the port that uses it (e.g. NOT/INC/SHL/SHR put Rdst in both Rd and Ra; STD puts the base in Ra and the data in Rb; CMP puts Rdst in Ra and Rsrc in Rb). This removes register-address muxes from decode.
- Opcodes as in [HLD §3.2](../architecture/HLD.md#32-opcodes-and-operand-placement): 00000 = NOP (empty memory is harmless), and `101cc` = JZ/JN/JC, with `cc` naming the flag.
- Unused opcodes 11101–11111 execute as NOP.

## Alternatives considered
| Option | Why not |
|---|---|
| 32-bit word + extra immediate word | Two-word fetch, an extra hazard and more ALMs, for no gain |
| 16-bit instructions, two per word | Complex fetch (half-word select) |

## Consequences
- Fetch is always one word, one cycle; the RAM output is the instruction register.
- The Phase-1 report explains why the "more than one memory location" note does not apply.
