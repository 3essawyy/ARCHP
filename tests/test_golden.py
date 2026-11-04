"""TC-105: the golden ISA model implements every ISA rule (ADR-005…010)."""

from __future__ import annotations

from pathlib import Path

import pytest

from archp import REPO_ROOT
from archp.assembler import assemble, assemble_file
from archp.cli import main
from archp.golden import Golden, State, alu, check_expect
from archp.isa import Op

PROGRAMS = sorted((REPO_ROOT / "programs").glob("*.asm"))


def run(src: str, inputs: list[int] | None = None, intr: list[int] | None = None) -> State:
    p = assemble(src)
    return Golden(p.image(), inputs or p.directives.inputs, intr or []).run()


# ---------------------------------------------------------------- ALU / flags (ADR-006)


@pytest.mark.parametrize(
    ("op", "a", "b", "imm", "res", "z", "n", "c", "c_we"),
    [
        (Op.ADD, 0xFFFFFFFF, 1, 0, 0, 1, 0, 1, True),
        (Op.ADD, 0x7FFFFFFF, 1, 0, 0x80000000, 0, 1, 0, True),
        (Op.SUB, 5, 7, 0, 0xFFFFFFFE, 0, 1, 1, True),  # borrow -> C=1
        (Op.SUB, 7, 5, 0, 2, 0, 0, 0, True),
        (Op.SUB, 5, 5, 0, 0, 1, 0, 0, True),
        (Op.CMP, 0xFFFFFFFF, 0xFFFFF325, 0, 0xCDA, 0, 0, 0, True),
        (Op.AND, 0xF0, 0x0F, 0, 0, 1, 0, 0, False),
        (Op.NOT, 0, 0, 0, 0xFFFFFFFF, 0, 1, 0, False),
        (Op.INC, 0xFFFFFFFF, 0, 0, 0, 1, 0, 1, True),
        (Op.IADD, 0x19, 0, 0xFFFF, 0x18, 0, 0, 1, True),  # sign-extended imm
        (Op.IADD, 1, 0, 0x7FFF, 0x8000, 0, 0, 0, True),
        (Op.SHL, 0x80000001, 0, 1, 2, 0, 0, 1, True),
        (Op.SHL, 0x1, 0, 31, 0x80000000, 0, 1, 0, True),
        (Op.SHL, 0x5, 0, 0, 0x5, 0, 0, 0, False),  # shift by 0: C untouched
        (Op.SHL, 0x5, 0, 0x21, 0xA, 0, 0, 0, True),  # amount = imm[4:0]
        (Op.SHR, 0x80000000, 0, 31, 1, 0, 0, 0, False),  # logical, never C
        (Op.SHR, 0x1, 0, 1, 0, 1, 0, 0, False),
    ],
)
def test_alu_rules(
    op: Op, a: int, b: int, imm: int, res: int, z: int, n: int, c: int, c_we: bool
) -> None:
    o = alu(op, a, b, imm)
    assert (o.result, o.z, o.n, o.c_we) == (res, z, n, c_we)
    if c_we:
        assert o.c == c
    assert o.zn_we


def test_alu_rejects_non_alu_op() -> None:
    with pytest.raises(ValueError, match="MOV"):
        alu(Op.MOV, 1)


# ---------------------------------------------------------------- semantics


def test_reset_vector_and_hlt_pc() -> None:
    s = run(".ORG 0\n20\n.ORG 20\nNOP\nHLT\nNOP")
    assert s.halted
    assert s.pc == 0x21
    assert s.retired == 2


def test_ldm_zero_extends_and_flags_untouched() -> None:
    s = run("SETC\nLDM R1, FFFF\nHLT")
    assert s.regs[1] == 0xFFFF
    assert s.c == 1


def test_in_returns_zero_when_inputs_exhausted() -> None:
    s = run("IN R1\nIN R2\nHLT", inputs=[0xAB])
    assert s.regs[1:3] == [0xAB, 0]


def test_stack_wraps_modulo_4k() -> None:
    # POP from the reset SP: SP = FFF+1 wraps to 000, R2 = M[000] (the reset vector).
    # PUSH then writes M[000] = 1 and SP returns to FFF.
    s = run(".ORG 0\n10\n.ORG 10\nLDM R1, 1\nPOP R2\nPUSH R1\nHLT")
    assert s.regs[2] == 0x10
    assert s.mem[0] == 1
    assert s.sp == 0xFFF


def test_unused_opcode_is_nop() -> None:
    p = assemble("NOP\nHLT")
    img = p.image()
    img[0] = 0b11111 << 27
    s = Golden(img).run()
    assert s.retired == 2
    assert s.regs == [0] * 8


def test_jump_clears_flag_only_when_taken() -> None:
    s = run("SETC\nJC 3\nNOP\nJC 6\nSETC\nJN 6\nHLT")
    # JC taken (C cleared) -> 3: JC not taken -> SETC -> JN not taken -> 6 HLT
    assert (s.c, s.pc) == (1, 6)


def test_hw_interrupt_context_and_return() -> None:
    src = """
    .ORG 0
    10
    .ORG 1
    50
    .ORG 10
    SETC          # 10
    LDM R1, 1     # 11  <- interrupt before this (after 1 retired)
    LDM R2, 2     # 12
    HLT           # 13
    .ORG 50
    LDM R7, 7
    SUB R7, R7, R7   # Z=1, C=0 inside the ISR
    RTI
    """
    s = run(src, intr=[1])
    assert s.hw_ints == [1]
    assert s.mem[0xFFF] == (0b100 << 29) | 0x11  # C=1 saved, return PC = 11
    assert (s.regs[1], s.regs[2], s.regs[7]) == (1, 2, 0)
    assert (s.c, s.n, s.z) == (1, 0, 0)  # restored by RTI
    assert s.sp == 0xFFF
    assert s.retired == 2 + 3 + 2  # SETC,LDM | ISR 3 | LDM,HLT


def test_back_to_back_interrupts_at_same_point() -> None:
    src = ".ORG 0\n10\n.ORG 1\n50\n.ORG 10\nNOP\nHLT\n.ORG 50\nINC R1\nRTI"
    s = run(src, intr=[0, 0])
    assert s.hw_ints == [0, 0]
    assert s.regs[1] == 2


def test_check_expect_reports_mismatches() -> None:
    s = run("LDM R1, 5\nOUT R1\nHLT")
    assert check_expect(s, [("R1", "5"), ("OUT", "5"), ("SP", "FFF")]) == []
    errs = check_expect(s, [("R1", "6"), ("OUT", "5,6"), ("M[10]", "1"), ("XX", "1")])
    assert len(errs) == 4


# ---------------------------------------------------------------- programs' own expectations


@pytest.mark.parametrize("path", PROGRAMS, ids=lambda p: p.stem)
def test_program_expectations_on_golden(path: Path) -> None:
    p = assemble_file(path)
    assert p.directives.expect, f"{path.name} has no #! expect line"
    if p.directives.intr_cycles:
        pytest.skip("interrupt timing comes from the RTL (tests/test_interrupts.py)")
    s = Golden(p.image(), p.directives.inputs).run()
    assert check_expect(s, p.directives.expect) == []


def test_cli_golden(capsys: pytest.CaptureFixture[str]) -> None:
    assert main(["golden", str(REPO_ROOT / "programs/one_operand.asm")]) == 0
    assert "expectations:" in capsys.readouterr().out
