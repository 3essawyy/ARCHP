"""TC-104: TA program format, data words, labels, directives, errors, output formats."""

from __future__ import annotations

from pathlib import Path

import pytest

from archp.assembler import AsmError, assemble, assemble_file, mem_text, mif_text, parse_number
from archp.cli import main
from archp.isa import Op, decode

DATA = Path(__file__).parent / "data" / "ta_lastterm"


def test_numbers_are_hex_by_default() -> None:
    assert parse_number("10") == 16
    assert parse_number("FF") == 255
    assert parse_number("0d10") == 10
    assert parse_number("0x1A") == 26
    assert parse_number("0b101") == 5
    assert parse_number("-4") == -4


def test_org_data_words_and_case_insensitivity() -> None:
    p = assemble(
        """
        # comment
        .ORG 0          #reset vector
        10
        .org 10
        in r1           ; lower case + semicolon comment
        Push R4
        inc   r1
        IADD R1, R1, 10
        """
    )
    assert p.words[0] == 0x10
    assert decode(p.words[0x10]).op is Op.IN
    assert decode(p.words[0x11]).op is Op.PUSH
    assert decode(p.words[0x13]).imm == 0x10
    assert p.code == {0x10, 0x11, 0x12, 0x13}


def test_labels_forward_and_backward() -> None:
    p = assemble(
        """
        .ORG 0
        start
        .ORG 20
        start: LDM R1, 3
        loop:
          SUB R1, R1, R2
          JZ done
          JMP loop
        done: HLT
        table: .WORD -1
        """
    )
    assert p.words[0] == 0x20
    assert p.labels == {"start": 0x20, "loop": 0x21, "done": 0x24, "table": 0x25}
    assert decode(p.words[0x22]).imm == 0x24
    assert decode(p.words[0x23]).imm == 0x21
    assert p.words[0x25] == 0xFFFFFFFF


def test_memory_operand_spacing_and_label_offset() -> None:
    p = assemble("LDD R1, 4 ( R2 )\nSTD R3,0(R4)\nLDD R0, tbl(R1)\ntbl: 5")
    assert (decode(p.words[0]).imm, decode(p.words[0]).ra) == (4, 2)
    assert (decode(p.words[1]).ra, decode(p.words[1]).rb) == (4, 3)
    assert decode(p.words[2]).imm == 3


def test_directives() -> None:
    p = assemble(
        """
        #! in: 30 50 FFFFFFFF
        #! intr: 40 95
        #! expect: R1=30 SP=FFE Z=1 M[210]=5 OUT=30,50
        #! max_cycles: 900
        NOP
        """
    )
    d = p.directives
    assert d.inputs == [0x30, 0x50, 0xFFFFFFFF]
    assert d.intr_cycles == [40, 95]
    assert ("M[210]", "5") in d.expect
    assert ("OUT", "30,50") in d.expect
    assert d.max_cycles == 900


@pytest.mark.parametrize(
    ("src", "msg"),
    [
        ("FOO R1", "unknown mnemonic"),
        ("ADD R1, R2", "takes 3 operand"),
        ("MOV R8, R1", "invalid register"),
        ("LDM R1, -1", "out of range"),
        ("LDM R1, 10000", "out of range"),
        ("IADD R1, R1, 8000", ""),  # 0x8000 is a valid 16-bit pattern
        ("JMP 1000", "jump target"),
        ("INT 2", "INT index"),
        ("JMP nowhere", "undefined label"),
        ("IADD R1, R2, R3", "got register"),
        ("FOO", "undefined label"),
        ("x: NOP\nx: NOP", "duplicate label"),
        ("NOP\n.ORG 0\nNOP", "already used by line 1"),
        (".ORG 1000", "outside"),
        ("LDD R1, R2", "invalid memory operand"),
        ("#! bogus: 1", "unknown directive"),
    ],
)
def test_errors_have_line_numbers(src: str, msg: str) -> None:
    if not msg:
        assemble(src)
        return
    with pytest.raises(AsmError, match=msg) as ei:
        assemble(src, source="t.asm")
    assert str(ei.value).startswith("t.asm:")


@pytest.mark.parametrize("name", ["Memory.txt", "OneOperand.txt", "TwoOperand.txt"])
def test_last_term_ta_programs_assemble(name: str) -> None:
    p = assemble_file(DATA / name)
    assert 0 in p.words  # reset vector present
    assert len(p.code) > 5


def test_last_term_branch_typo_is_reported_clearly() -> None:
    # Branch.txt line 19 really says "IADD R1, R2, R3" (a register where Imm belongs).
    with pytest.raises(AsmError, match=r"Branch.txt:19: expected a number or label, got register"):
        assemble_file(DATA / "Branch.txt")
    fixed = (DATA / "Branch.txt").read_text().replace("IADD R1, R2, R3", "IADD R1, R2, 3")
    assert len(assemble(fixed).code) > 20


def test_mem_and_mif_formats() -> None:
    p = assemble(".ORG 0\n4\n.ORG 4\nLDM R1, 5\nHLT")
    mem = mem_text(p).splitlines()
    assert len(mem) == 4096
    assert mem[0] == "00000004"
    assert mem[4] == f"{p.words[4]:08X}"
    assert all(len(line) == 8 for line in mem)
    mif = mif_text(p)
    assert "DEPTH = 4096;" in mif
    assert "WIDTH = 32;" in mif
    assert "000 : 00000004;" in mif
    assert "[001..003] : 00000000;" in mif
    assert mif.rstrip().endswith("END;")


def test_cli_asm_writes_outputs(tmp_path: Path) -> None:
    src = tmp_path / "p.asm"
    src.write_text(".ORG 0\n2\n.ORG 2\nHLT\n")
    assert main(["asm", str(src)]) == 0
    assert (tmp_path / "p.mem").read_text().splitlines()[2] == f"{Op.HLT << 27:08X}"
    assert (tmp_path / "p.mif").exists()
    assert "HLT" in (tmp_path / "p.lst").read_text()
    bad = tmp_path / "bad.asm"
    bad.write_text("FOO\n")
    assert main(["asm", str(bad)]) == 1
