"""TC-103: every instruction encodes per HLD §3.2 (table-driven)."""

from __future__ import annotations

import pytest

from archp.assembler import assemble
from archp.isa import SPECS, Op, decode, disassemble, encode, sext16

# (source, opcode, rd, ra, rb, imm) — the HLD §3.2 operand placement
CASES = [
    ("NOP", 0b00000, 0, 0, 0, 0),
    ("HLT", 0b00001, 0, 0, 0, 0),
    ("SETC", 0b00010, 0, 0, 0, 0),
    ("NOT R3", 0b00011, 3, 3, 0, 0),
    ("INC R4", 0b00100, 4, 4, 0, 0),
    ("OUT R5", 0b00101, 0, 5, 0, 0),
    ("IN R6", 0b00110, 6, 0, 0, 0),
    ("MOV R1, R2", 0b00111, 1, 2, 0, 0),
    ("SWAP R1, R2", 0b01000, 1, 2, 1, 0),
    ("ADD R1, R2, R3", 0b01001, 1, 2, 3, 0),
    ("SUB R7, R6, R5", 0b01010, 7, 6, 5, 0),
    ("AND R0, R1, R2", 0b01011, 0, 1, 2, 0),
    ("IADD R1, R2, FFFF", 0b01100, 1, 2, 0, 0xFFFF),
    ("IADD R1, R2, -1", 0b01100, 1, 2, 0, 0xFFFF),
    ("CMP R3, R4", 0b01101, 0, 3, 4, 0),
    ("SHR R2, 3", 0b01110, 2, 2, 0, 3),
    ("SHL R2, 1F", 0b01111, 2, 2, 0, 0x1F),
    ("PUSH R3", 0b10000, 0, 0, 3, 0),
    ("POP R4", 0b10001, 4, 0, 0, 0),
    ("LDM R1, FFFF", 0b10010, 1, 0, 0, 0xFFFF),
    ("LDD R1, 200(R5)", 0b10011, 1, 5, 0, 0x200),
    ("STD R2, 201(R5)", 0b10100, 0, 5, 2, 0x201),
    ("STD R2, -1(R5)", 0b10100, 0, 5, 2, 0xFFFF),
    ("JZ 30", 0b10101, 0, 0, 0, 0x30),
    ("JN 31", 0b10110, 0, 0, 0, 0x31),
    ("JC 32", 0b10111, 0, 0, 0, 0x32),
    ("JMP FFF", 0b11000, 0, 0, 0, 0xFFF),
    ("CALL 300", 0b11001, 0, 0, 0, 0x300),
    ("RET", 0b11010, 0, 0, 0, 0),
    ("INT 1", 0b11011, 0, 0, 0, 1),
    ("RTI", 0b11100, 0, 0, 0, 0),
]


def test_every_mnemonic_is_covered() -> None:
    assert {c[0].split()[0] for c in CASES} == set(SPECS)
    assert {s.op for s in SPECS.values()} == set(Op)


@pytest.mark.parametrize(("src", "opc", "rd", "ra", "rb", "imm"), CASES)
def test_encoding(src: str, opc: int, rd: int, ra: int, rb: int, imm: int) -> None:
    word = assemble(src).words[0]
    expected = (opc << 27) | (rd << 24) | (ra << 21) | (rb << 18) | imm
    assert word == expected, f"{src}: {word:08X} != {expected:08X}"
    d = decode(word)
    assert (d.opcode, d.rd, d.ra, d.rb, d.imm) == (opc, rd, ra, rb, imm)
    assert word & (0b11 << 16) == 0  # bits 17:16 always zero


def test_conditional_jump_opcodes_name_the_flag() -> None:
    # 101cc: cc = 01 Z, 10 N, 11 C (HLD §3.2)
    assert [Op.JZ & 3, Op.JN & 3, Op.JC & 3] == [1, 2, 3]
    assert all(op >> 2 == 0b101 for op in (Op.JZ, Op.JN, Op.JC))


def test_unused_opcodes_decode_as_nop() -> None:
    for opc in (0b11101, 0b11110, 0b11111):
        assert decode(opc << 27).op is Op.NOP


def test_disassemble_round_trip() -> None:
    for src, *_ in CASES:
        word = assemble(src).words[0]
        assert assemble(disassemble(word)).words[0] == word


def test_encode_rejects_bad_fields() -> None:
    with pytest.raises(ValueError, match="rd"):
        encode(Op.ADD, rd=8)
    with pytest.raises(ValueError, match="imm"):
        encode(Op.LDM, imm=0x10000)


def test_sext16() -> None:
    assert sext16(0x7FFF) == 0x7FFF
    assert sext16(0x8000) == 0xFFFF8000
    assert sext16(0xFFFF) == 0xFFFFFFFF
