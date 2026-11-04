"""Golden ISA model: the executable specification of ARCHP (T-004, ADR-013).

Instruction-level (not cycle-accurate). Semantics follow the brief as
interpreted by ADR-005 (immediates), ADR-006 (flags), ADR-007 (interrupts,
context word), ADR-009 (12-bit PC/SP) and ADR-010 (HLT).

Hardware interrupts are injected *before* the instruction that would be the
N-th to retire, for each N in ``intr_points`` (the RTL testbench logs these
counts, so the model replays an interrupt at the same architectural point).
"""

from __future__ import annotations

from collections.abc import Iterable, Sequence
from dataclasses import dataclass, field

from archp.isa import (
    ADDR_MASK,
    CTX_FLAG_SHIFT,
    HW_INT_VECTOR,
    INT_VECTOR_BASE,
    MEM_WORDS,
    RESET_VECTOR,
    SP_RESET,
    WORD_MASK,
    Op,
    decode,
    sext16,
)

#: ADR-006: SUB/CMP set C on unsigned borrow (A < B). Flip (with the RTL
#: constant C_SUB_CARRY_IS_BORROW) to switch to the "carry = not borrow" convention.
SUB_CARRY_IS_BORROW = True


@dataclass(frozen=True)
class AluOut:
    result: int
    z: int
    n: int
    c: int
    zn_we: bool
    c_we: bool


def _zn(r: int) -> tuple[int, int]:
    return int(r == 0), (r >> 31) & 1


def alu(op: Op, a: int, b: int = 0, imm: int = 0) -> AluOut:
    """Reference ALU for the flag-setting operations (also used to check the RTL ALU).

    ``a``/``b`` are 32-bit operands, ``imm`` is the raw 16-bit immediate.
    """
    a &= WORD_MASK
    b &= WORD_MASK
    if op in (Op.ADD, Op.IADD, Op.INC):
        rhs = {Op.ADD: b, Op.IADD: sext16(imm), Op.INC: 1}[op]
        full = a + rhs
        r = full & WORD_MASK
        return AluOut(r, *_zn(r), (full >> 32) & 1, True, True)
    if op in (Op.SUB, Op.CMP):
        r = (a - b) & WORD_MASK
        borrow = int(a < b)
        c = borrow if SUB_CARRY_IS_BORROW else 1 - borrow
        return AluOut(r, *_zn(r), c, True, True)
    if op is Op.AND:
        r = a & b
        return AluOut(r, *_zn(r), 0, True, False)
    if op is Op.NOT:
        r = ~a & WORD_MASK
        return AluOut(r, *_zn(r), 0, True, False)
    if op is Op.SHL:
        sh = imm & 31
        r = (a << sh) & WORD_MASK
        c = (a >> (32 - sh)) & 1 if sh else 0
        return AluOut(r, *_zn(r), c, True, sh != 0)
    if op is Op.SHR:
        sh = imm & 31
        r = a >> sh
        return AluOut(r, *_zn(r), 0, True, False)
    raise ValueError(f"{op.name} is not a flag-setting ALU operation")


@dataclass
class State:
    regs: list[int] = field(default_factory=lambda: [0] * 8)
    pc: int = 0
    sp: int = SP_RESET
    z: int = 0
    n: int = 0
    c: int = 0
    mem: list[int] = field(default_factory=lambda: [0] * MEM_WORDS)
    out: list[int] = field(default_factory=list)
    halted: bool = False
    retired: int = 0
    #: retired-instruction count at which each hardware interrupt was taken
    hw_ints: list[int] = field(default_factory=list)

    @property
    def flags(self) -> int:
        """CCR<2:0> = C N Z."""
        return (self.c << 2) | (self.n << 1) | self.z


class Golden:
    def __init__(
        self,
        image: Sequence[int],
        inputs: Iterable[int] = (),
        intr_points: Iterable[int] = (),
    ) -> None:
        if len(image) != MEM_WORDS:
            raise ValueError(f"image must have {MEM_WORDS} words")
        self.s = State(mem=[w & WORD_MASK for w in image])
        self._inputs = list(inputs)
        self._intr = sorted(intr_points)
        self.s.pc = self.s.mem[RESET_VECTOR] & ADDR_MASK  # reset: PC <- M[0]

    # -------------------------------------------------------------- helpers
    def _push(self, w: int) -> None:
        s = self.s
        s.mem[s.sp] = w & WORD_MASK
        s.sp = (s.sp - 1) & ADDR_MASK

    def _pop(self) -> int:
        s = self.s
        s.sp = (s.sp + 1) & ADDR_MASK
        return s.mem[s.sp]

    def _context(self, ret_pc: int) -> int:
        return (self.s.flags << CTX_FLAG_SHIFT) | (ret_pc & ADDR_MASK)

    def _set(self, a: AluOut) -> None:
        if a.zn_we:
            self.s.z, self.s.n = a.z, a.n
        if a.c_we:
            self.s.c = a.c

    # -------------------------------------------------------------- execution
    def step(self) -> bool:
        """Execute one instruction (after any due interrupt). False once halted."""
        s = self.s
        if s.halted:
            return False
        while self._intr and self._intr[0] <= s.retired:
            self._intr.pop(0)
            s.hw_ints.append(s.retired)
            self._push(self._context(s.pc))
            s.pc = s.mem[HW_INT_VECTOR] & ADDR_MASK

        d = decode(s.mem[s.pc])
        op, r = d.op, s.regs
        npc = (s.pc + 1) & ADDR_MASK
        nxt = npc
        s.retired += 1

        if op is Op.HLT:
            s.halted = True
            return False
        if op is Op.SETC:
            s.c = 1
        elif op in (Op.NOT, Op.INC, Op.SHL, Op.SHR):
            a = alu(op, r[d.ra], imm=d.imm)
            r[d.rd] = a.result
            self._set(a)
        elif op in (Op.ADD, Op.SUB, Op.AND):
            a = alu(op, r[d.ra], r[d.rb])
            r[d.rd] = a.result
            self._set(a)
        elif op is Op.IADD:
            a = alu(op, r[d.ra], imm=d.imm)
            r[d.rd] = a.result
            self._set(a)
        elif op is Op.CMP:
            self._set(alu(op, r[d.ra], r[d.rb]))
        elif op is Op.OUT:
            s.out.append(r[d.ra])
        elif op is Op.IN:
            r[d.rd] = self._inputs.pop(0) & WORD_MASK if self._inputs else 0
        elif op is Op.MOV:
            r[d.rd] = r[d.ra]
        elif op is Op.SWAP:  # Rd=Rdst, Ra=Rsrc, Rb=Rdst
            r[d.rd], r[d.ra] = r[d.ra], r[d.rb]
        elif op is Op.PUSH:
            self._push(r[d.rb])
        elif op is Op.POP:
            r[d.rd] = self._pop()
        elif op is Op.LDM:
            r[d.rd] = d.imm
        elif op is Op.LDD:
            r[d.rd] = s.mem[(r[d.ra] + sext16(d.imm)) & ADDR_MASK]
        elif op is Op.STD:
            s.mem[(r[d.ra] + sext16(d.imm)) & ADDR_MASK] = r[d.rb]
        elif op in (Op.JZ, Op.JN, Op.JC):
            flag = {Op.JZ: "z", Op.JN: "n", Op.JC: "c"}[op]
            if getattr(s, flag):
                setattr(s, flag, 0)
                nxt = d.imm & ADDR_MASK
        elif op is Op.JMP:
            nxt = d.imm & ADDR_MASK
        elif op is Op.CALL:
            self._push(npc)
            nxt = d.imm & ADDR_MASK
        elif op is Op.RET:
            nxt = self._pop() & ADDR_MASK
        elif op is Op.INT:
            self._push(self._context(npc))
            nxt = s.mem[INT_VECTOR_BASE + (d.imm & 1)] & ADDR_MASK
        elif op is Op.RTI:
            w = self._pop()
            nxt = w & ADDR_MASK
            s.c, s.n, s.z = (w >> 31) & 1, (w >> 30) & 1, (w >> 29) & 1
        # NOP and unused opcodes: nothing
        s.pc = nxt
        return True

    def run(self, max_steps: int = 100_000) -> State:
        for _ in range(max_steps):
            if not self.step():
                return self.s
        raise RuntimeError(f"program did not halt within {max_steps} instructions")


# ------------------------------------------------------------------ expectations


def check_expect(state: State, expect: Iterable[tuple[str, str]]) -> list[str]:
    """Evaluate ``#! expect`` items (hex values) against a final state."""
    errors: list[str] = []
    for key, val in expect:
        if key == "OUT":
            want = [int(v, 16) & WORD_MASK for v in val.split(",") if v]
            got: object = state.out
            ok = state.out == want
        else:
            want_v = int(val, 16) & WORD_MASK
            if key.startswith("R") and key[1:].isdigit():
                got = state.regs[int(key[1:])]
            elif key in ("SP", "PC", "Z", "N", "C"):
                got = getattr(state, key.lower())
            elif key == "FLAGS":
                got = state.flags
            elif key.startswith("M[") and key.endswith("]"):
                got = state.mem[int(key[2:-1], 16) & ADDR_MASK]
            else:
                errors.append(f"unknown expect key {key}")
                continue
            ok = got == want_v
            want = [want_v]
        if not ok:
            shown = f"{got:X}" if isinstance(got, int) else [f"{x:X}" for x in got]  # type: ignore[attr-defined]
            errors.append(f"{key}: expected {val}, got {shown}")
    return errors
