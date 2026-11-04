# Requirements (extracted from the brief)

Source: [Architecture_Project_Fa26.pdf](Architecture_Project_Fa26.pdf). Paraphrased into traceable IDs. If this file and the PDF disagree, the PDF wins — fix this file. Where the brief is ambiguous, the interpretation we chose is linked to its ADR.

## General / architecture (G)

| ID | Requirement | Interpretation |
|---|---|---|
| REQ-G1 | 6-stage pipeline: Fetch, Decode (control signals), Execute-1 (ALU), Execute-2 (branch resolution, LDD/STD address), Memory, Write-Back. | [ADR-014](../decisions/ADR-014-stage-mapping.md) |
| REQ-G2 | Von-Neumann: **one** memory for program and data. | [ADR-004](../decisions/ADR-004-unified-memory.md) |
| REQ-G3 | RISC-like ISA; 8 x 32-bit GPRs R0–R7; PC and SP (32-bit in the spec); CCR<3:0> with Z=CCR<0>, N=CCR<1>, C=CCR<2>. | PC/SP physical width: [ADR-009](../decisions/ADR-009-pc-sp-width.md) |
| REQ-G4 | SP initial value 2^12−1 (0xFFF). Memory is 4K words (4096 x 32), synchronous read (data one cycle after the address); 32-bit data bus. | |
| REQ-G5 | Ports: IN.PORT<31:0>, OUT.PORT<31:0>, INTR.IN (single non-maskable interrupt), RESET.IN. | INTR sampling: [ADR-007](../decisions/ADR-007-interrupts.md) |
| REQ-G6 | Interrupt: finish instructions already in the pipeline, push the address of the next instruction, PC ← M[1]; flags preserved. RTI pops PC (and restores flags) and resumes after the interrupted instruction. Handle corner cases (e.g. branching). | [ADR-007](../decisions/ADR-007-interrupts.md) |
| REQ-G7 | Reset: PC ← M[0]. | |
| REQ-G8 | Instruction fields: Rsrc1, Rsrc2, Rdst, Offset (16 bit), Imm (16 bit). "Some instructions will occupy more than one memory location". | [ADR-003](../decisions/ADR-003-instruction-format.md) (one 32-bit word each) |

## Instruction set (ISA)

| ID | Instructions | Semantics notes | ADR |
|---|---|---|---|
| REQ-I1 | NOP, HLT, SETC | HLT freezes the CPU until reset | [ADR-010](../decisions/ADR-010-hlt.md) |
| REQ-I2 | NOT Rdst, INC Rdst | NOT: Z,N; INC: Z,N,C | [ADR-006](../decisions/ADR-006-flag-semantics.md) |
| REQ-I3 | OUT Rsrc, IN Rdst | | |
| REQ-I4 | MOV Rdst,Rsrc; SWAP Rdst,Rsrc | SWAP exchanges two registers | [ADR-008](../decisions/ADR-008-swap-micro-ops.md) |
| REQ-I5 | ADD, SUB, AND Rdst,Rsrc1,Rsrc2 | ADD/SUB: Z,N,C; AND: Z,N | [ADR-006](../decisions/ADR-006-flag-semantics.md) |
| REQ-I6 | IADD Rdst,Rsrc,Imm | Z,N,C; Imm sign-extended | [ADR-005](../decisions/ADR-005-immediate-extension.md) |
| REQ-I7 | CMP Rdst,Rsrc | Rdst − Rsrc, result discarded, Z,N,C | [ADR-006](../decisions/ADR-006-flag-semantics.md) |
| REQ-I8 | SHR Rdst,Imm; SHL Rdst,Imm | SHR: Z,N; SHL: Z,N,C | [ADR-006](../decisions/ADR-006-flag-semantics.md) |
| REQ-I9 | PUSH Rsrc; POP Rdst | X[SP]←R; SP−=1 / SP+=1; R←X[SP] | |
| REQ-I10 | LDM Rdst,Imm | R ← Imm<15:0> (zero-extended) | [ADR-005](../decisions/ADR-005-immediate-extension.md) |
| REQ-I11 | LDD Rdst,offset(Rsrc); STD Rsrc1,offset(Rsrc2) | M[R+offset] | [ADR-005](../decisions/ADR-005-immediate-extension.md) |
| REQ-I12 | JZ, JN, JC Imm | Jump if flag; the tested flag is cleared when taken | [ADR-006](../decisions/ADR-006-flag-semantics.md) |
| REQ-I13 | JMP Imm; CALL Imm; RET | CALL: X[SP]←PC+1; SP−=1; PC←Imm. RET: SP+=1; PC←X[SP] | |
| REQ-I14 | INT index (0/1); RTI | INT: X[SP]←PC+1; SP−=1; flags saved; PC←M[index+2]. RTI: SP+=1; PC←X[SP]; flags restored | [ADR-007](../decisions/ADR-007-interrupts.md) |

## Phase 1 — Week 11 (P1)

| ID | Deliverable |
|---|---|
| REQ-P1-1 | Instruction format: opcode of each instruction, instruction bit details. |
| REQ-P1-2 | Schematic of the processor with data flow details, drawn with a digital tool: ALU/registers/memory blocks, interconnections and their sizes, control unit detailed design. |
| REQ-P1-3 | Pipeline stages design; pipeline register details (size, inputs, connections). |
| REQ-P1-4 | Pipeline hazards and solutions, including data forwarding and static branch prediction. |

## Phase 2 — Week 13 (P2)

| ID | Deliverable |
|---|---|
| REQ-P2-1 | VHDL implementation of each component and one integrating top-level module. |
| REQ-P2-2 | Simulation test code that reads a program file and executes it; simulation wave set up; load memory file and run the test program. |
| REQ-P2-3 | Assembler: assembly text file → memory file in our encoding. |
| REQ-P2-4 | Report: design changes after Phase 1. |
| REQ-P2-5 | Report: pipeline hazards considered and how the design solves them. |
| REQ-P2-6 | Quartus Flow Summary screenshot of the static-prediction version (and of the final version if different). |
| REQ-P2-7 | Memory implemented with on-chip RAM blocks (M10K): "Total block memory bits" non-zero, otherwise not ranked. |

## Testing and evaluation (E)

| ID | Requirement |
|---|---|
| REQ-E1 | TA test programs: assemble, load onto the RAM, reset; execution starts at M[0]. Notify the TA of unimplemented or broken instructions. |
| REQ-E2 | Waveform via do-files with main signals only: R0–R7, PC, SP, Flags, CLK, Reset, Interrupt, IN.port, OUT.port. |
| REQ-E3 | The design must generate the programming file (full Quartus compile). |
| REQ-E4 | Quartus Prime Lite 16.1 (16.1.0.196), Cyclone V, 5CSEMA5F31C6, **default compiler settings**; Flow Summary (ALMs, total registers). |
| REQ-E5 | Grading: instructions 12, resource ranking 5, data hazards 1, structural hazards 1, control hazards 1; bonus 2 for 2-bit dynamic prediction with address calculation in fetch. |
| REQ-E6 | A non-working processor nullifies the grade; no credit for separate modules. Unnecessary latching or poor hardware understanding is penalised. |
| REQ-E7 | Ranking: only designs passing all tests; logic utilization (ALMs), ties by total registers; on the **static-prediction** build. The dynamic predictor must be disable-able by a VHDL generic/constant; both builds must pass all tests. |
| REQ-E8 | Max 4 team members; individual grades can differ (balanced work distribution). |

## General advice we adopt as rules (A)

| ID | Rule |
|---|---|
| REQ-A1 | Integrate incrementally; compile often; don't ignore warnings; no latches. |
| REQ-A2 | Reset every component at the start of simulation; never leave an input as `U`. |
| REQ-A3 | Use do-files rather than manual forcing; save RAM files. |
