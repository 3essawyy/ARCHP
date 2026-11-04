"""TC-106: self-checking VHDL unit testbenches (GHDL), incl. ALU vs golden alu()."""

from __future__ import annotations

import random
from pathlib import Path

import pytest

from archp import REPO_ROOT, ghdl
from archp.golden import alu
from archp.isa import Op, sext16

from .conftest import requires_ghdl

RTL = REPO_ROOT / "rtl"
TB = REPO_ROOT / "tb"
PKG = [TB / "tb_util_pkg.vhd", RTL / "pkg/archp_pkg.vhd"]

ALU_CODE = {"ADD": 0, "SUB": 1, "AND": 2, "NOT": 3, "INC": 4, "PASSA": 5, "PASSB": 6}
ALU_CODE |= {"SHL": 7, "SHR": 8, "IN": 9, "SETC": 10}
EDGES = [0, 1, 2, 0x7FFFFFFF, 0x80000000, 0xFFFFFFFF, 0xFFFFFFFE, 0xFFFFF325, 0x19, 0x5]


def _check_pass(tb_out: str) -> None:
    assert "TB_DONE" in tb_out, tb_out
    assert "errors=0" in tb_out or "errors=" not in tb_out, tb_out


def _alu_vectors() -> list[str]:
    rng = random.Random(301)
    pairs = [(a, b) for a in EDGES for b in EDGES]
    pairs += [(rng.getrandbits(32), rng.getrandbits(32)) for _ in range(300)]
    lines: list[str] = []

    def emit(
        code: str, a: int, b: int, sh: int, inp: int, res: int, c: int, zn: bool, cw: bool
    ) -> None:
        z, n = int(res == 0), (res >> 31) & 1
        fields = (ALU_CODE[code], a, b, sh, inp, res, z, n, c, int(zn), int(cw))
        lines.append("{:X} {:08X} {:08X} {:02X} {:08X} {:08X} {} {} {} {} {}".format(*fields))

    for i, (a, b) in enumerate(pairs):
        imm = b & 0xFFFF
        sh = imm & 31
        for op, code, bb in (
            (Op.ADD, "ADD", b),
            (Op.SUB, "SUB", b),
            (Op.AND, "AND", b),
            (Op.NOT, "NOT", b),
            (Op.INC, "INC", b),
            (Op.IADD, "ADD", sext16(imm)),  # IADD = ADD with sign-extended imm on B
        ):
            o = alu(op, a, b, imm)
            emit(code, a, bb, sh, 0, o.result, o.c, o.zn_we, o.c_we)
        for op, code in ((Op.SHL, "SHL"), (Op.SHR, "SHR")):
            o = alu(op, a, 0, imm)
            emit(code, a, b, sh, 0, o.result, o.c, o.zn_we, o.c_we)
        inp = (a ^ b ^ i) & 0xFFFFFFFF
        emit("PASSA", a, b, sh, inp, a, 0, False, False)
        emit("PASSB", a, b, sh, inp, b, 0, False, False)
        emit("IN", a, b, sh, inp, inp, 0, False, False)
        emit("SETC", a, b, sh, inp, a, 1, False, True)
    return lines


@requires_ghdl
def test_alu_matches_golden(tmp_path: Path) -> None:
    vec = tmp_path / "alu_vectors.txt"
    lines = _alu_vectors()
    vec.write_text("\n".join(lines) + "\n")
    ghdl.analyse([*PKG, RTL / "execute/alu.vhd", TB / "unit/tb_alu.vhd"], tmp_path)
    res = ghdl.run("tb_alu", tmp_path, {"G_VECTORS": str(vec)})
    assert res.returncode == 0, res.output[-3000:]
    assert f"vectors={len(lines)} errors=0" in res.output, res.output[-3000:]


@requires_ghdl
def test_register_file(tmp_path: Path) -> None:
    ghdl.analyse(
        [*PKG, RTL / "decode/register_file.vhd", TB / "unit/tb_register_file.vhd"], tmp_path
    )
    res = ghdl.run("tb_register_file", tmp_path)
    assert res.returncode == 0, res.output
    _check_pass(res.output)


@requires_ghdl
def test_memory(tmp_path: Path) -> None:
    init = tmp_path / "mem_init.txt"
    init.write_text("// header comment\n00000004\n11111111\n22222222\n\n@0FF\nABCD0123\n")
    ghdl.analyse([*PKG, RTL / "memory/unified_memory.vhd", TB / "unit/tb_memory.vhd"], tmp_path)
    res = ghdl.run("tb_memory", tmp_path, {"G_INIT_FILE": str(init)})
    assert res.returncode == 0, res.output
    _check_pass(res.output)


@requires_ghdl
def test_ccr(tmp_path: Path) -> None:
    ghdl.analyse([*PKG, RTL / "execute/ccr.vhd", TB / "unit/tb_ccr.vhd"], tmp_path)
    res = ghdl.run("tb_ccr", tmp_path)
    assert res.returncode == 0, res.output
    _check_pass(res.output)


def test_rtl_carry_switch_matches_golden() -> None:
    from archp import golden

    pkg = (RTL / "pkg/archp_pkg.vhd").read_text()
    want = "true" if golden.SUB_CARRY_IS_BORROW else "false"
    assert f"C_SUB_CARRY_IS_BORROW : boolean := {want};" in pkg


@pytest.mark.parametrize("path", sorted(RTL.rglob("*.vhd")), ids=lambda p: p.name)
def test_rtl_has_no_vhdl2008_constructs(path: Path) -> None:
    text = path.read_text().lower()
    for bad in ("process(all)", "process (all)", "?=", "std.env"):
        assert bad not in text, f"{path.name} uses VHDL-2008 '{bad}' (ADR-002)"
