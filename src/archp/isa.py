"""ISA definition: the single source of truth for the instruction encoding (ADR-003).

Word layout (one 32-bit word per instruction)::

    [31:27] opcode | [26:24] Rd | [23:21] Ra | [20:18] Rb | [17:16] 00 | [15:0] imm

* ``Rd`` is the register-file write address.
* ``Ra`` is read port A (ALU operand A, LDD/STD base, OUT source).
* ``Rb`` is read port B (ALU operand B, PUSH/STD store data).

Each syntactic operand of an instruction is mapped to one or more of these
fields by :data:`SPECS`, so the hardware never needs register-address muxes.
"""

from __future__ import annotations

from dataclasses import dataclass
from enum import Enum, IntEnum

WORD_MASK = 0xFFFF_FFFF
ADDR_BITS = 12
ADDR_MASK = (1 << ADDR_BITS) - 1
MEM_WORDS = 1 << ADDR_BITS
SP_RESET = ADDR_MASK

RESET_VECTOR = 0
HW_INT_VECTOR = 1
INT_VECTOR_BASE = 2

#: Context word saved by INT / interrupt: [31]=C, [30]=N, [29]=Z (ADR-007).
CTX_FLAG_SHIFT = 29


class Op(IntEnum):
    NOP = 0b00000
    HLT = 0b00001
    SETC = 0b00010
    NOT = 0b00011
    INC = 0b00100
    OUT = 0b00101
    IN = 0b00110
    MOV = 0b00111
    SWAP = 0b01000
    ADD = 0b01001
    SUB = 0b01010
    AND = 0b01011
    IADD = 0b01100
    CMP = 0b01101
    SHR = 0b01110
    SHL = 0b01111
    PUSH = 0b10000
    POP = 0b10001
    LDM = 0b10010
    LDD = 0b10011
    STD = 0b10100
    JZ = 0b10101
    JN = 0b10110
    JC = 0b10111
    JMP = 0b11000
    CALL = 0b11001
    RET = 0b11010
    INT = 0b11011
    RTI = 0b11100


class Field(Enum):
    RD = "rd"
    RA = "ra"
    RB = "rb"


class Arg(Enum):
    """Syntactic operand kinds."""

    REG = "reg"  # R0..R7
    SIMM = "simm"  # 16-bit, may be negative (sign-extended by hardware)
    UIMM = "uimm"  # 16-bit unsigned (zero-extended by hardware)
    TARGET = "target"  # 12-bit address (number or label)
    INDEX = "index"  # 0 or 1 (INT)
    MEM = "mem"  # offset(Rbase): signed offset + register


@dataclass(frozen=True)
class Operand:
    kind: Arg
    #: Fields a REG (or the base register of MEM) is written into.
    fields: tuple[Field, ...] = ()


@dataclass(frozen=True)
class Spec:
    op: Op
    operands: tuple[Operand, ...]
    syntax: str


def _r(*fields: Field) -> Operand:
    return Operand(Arg.REG, fields)


_RD, _RA, _RB = Field.RD, Field.RA, Field.RB

SPECS: dict[str, Spec] = {
    s.op.name: s
    for s in (
        Spec(Op.NOP, (), "NOP"),
        Spec(Op.HLT, (), "HLT"),
        Spec(Op.SETC, (), "SETC"),
        Spec(Op.NOT, (_r(_RD, _RA),), "NOT Rdst"),
        Spec(Op.INC, (_r(_RD, _RA),), "INC Rdst"),
        Spec(Op.OUT, (_r(_RA),), "OUT Rsrc"),
        Spec(Op.IN, (_r(_RD),), "IN Rdst"),
        Spec(Op.MOV, (_r(_RD), _r(_RA)), "MOV Rdst, Rsrc"),
        Spec(Op.SWAP, (_r(_RD, _RB), _r(_RA)), "SWAP Rdst, Rsrc"),
        Spec(Op.ADD, (_r(_RD), _r(_RA), _r(_RB)), "ADD Rdst, Rsrc1, Rsrc2"),
        Spec(Op.SUB, (_r(_RD), _r(_RA), _r(_RB)), "SUB Rdst, Rsrc1, Rsrc2"),
        Spec(Op.AND, (_r(_RD), _r(_RA), _r(_RB)), "AND Rdst, Rsrc1, Rsrc2"),
        Spec(Op.IADD, (_r(_RD), _r(_RA), Operand(Arg.SIMM)), "IADD Rdst, Rsrc, Imm"),
        Spec(Op.CMP, (_r(_RA), _r(_RB)), "CMP Rdst, Rsrc"),
        Spec(Op.SHR, (_r(_RD, _RA), Operand(Arg.UIMM)), "SHR Rdst, Imm"),
        Spec(Op.SHL, (_r(_RD, _RA), Operand(Arg.UIMM)), "SHL Rdst, Imm"),
        Spec(Op.PUSH, (_r(_RB),), "PUSH Rsrc"),
        Spec(Op.POP, (_r(_RD),), "POP Rdst"),
        Spec(Op.LDM, (_r(_RD), Operand(Arg.UIMM)), "LDM Rdst, Imm"),
        Spec(Op.LDD, (_r(_RD), Operand(Arg.MEM, (_RA,))), "LDD Rdst, offset(Rsrc)"),
        Spec(Op.STD, (_r(_RB), Operand(Arg.MEM, (_RA,))), "STD Rsrc1, offset(Rsrc2)"),
        Spec(Op.JZ, (Operand(Arg.TARGET),), "JZ Imm"),
        Spec(Op.JN, (Operand(Arg.TARGET),), "JN Imm"),
        Spec(Op.JC, (Operand(Arg.TARGET),), "JC Imm"),
        Spec(Op.JMP, (Operand(Arg.TARGET),), "JMP Imm"),
        Spec(Op.CALL, (Operand(Arg.TARGET),), "CALL Imm"),
        Spec(Op.RET, (), "RET"),
        Spec(Op.INT, (Operand(Arg.INDEX),), "INT index"),
        Spec(Op.RTI, (), "RTI"),
    )
}


def encode(op: Op, rd: int = 0, ra: int = 0, rb: int = 0, imm: int = 0) -> int:
    """Pack fields into a 32-bit instruction word."""
    for name, v in (("rd", rd), ("ra", ra), ("rb", rb)):
        if not 0 <= v <= 7:
            raise ValueError(f"{name}={v} out of range 0..7")
    if not 0 <= imm <= 0xFFFF:
        raise ValueError(f"imm={imm:#x} out of range 0..0xFFFF")
    return (int(op) << 27) | (rd << 24) | (ra << 21) | (rb << 18) | imm


@dataclass(frozen=True)
class Decoded:
    opcode: int
    rd: int
    ra: int
    rb: int
    imm: int

    @property
    def op(self) -> Op:
        """Known opcode, or NOP for the unused codes 11101..11111 (ADR-003)."""
        try:
            return Op(self.opcode)
        except ValueError:
            return Op.NOP


def decode(word: int) -> Decoded:
    return Decoded(
        opcode=(word >> 27) & 0x1F,
        rd=(word >> 24) & 7,
        ra=(word >> 21) & 7,
        rb=(word >> 18) & 7,
        imm=word & 0xFFFF,
    )


def sext16(v: int) -> int:
    """Sign-extend a 16-bit value to a 32-bit pattern."""
    v &= 0xFFFF
    return (v | 0xFFFF_0000) if v & 0x8000 else v


def disassemble(word: int) -> str:
    """Human-readable text for listings (registers shown by syntactic role)."""
    d = decode(word)
    spec = SPECS[d.op.name]
    vals = {Field.RD: d.rd, Field.RA: d.ra, Field.RB: d.rb}
    parts: list[str] = []
    for o in spec.operands:
        if o.kind is Arg.REG:
            parts.append(f"R{vals[o.fields[0]]}")
        elif o.kind is Arg.MEM:
            parts.append(f"{d.imm:X}(R{d.ra})")
        elif o.kind is Arg.INDEX:
            parts.append(str(d.imm & 1))
        else:
            parts.append(f"{d.imm:X}")
    return d.op.name + (" " + ", ".join(parts) if parts else "")
