"""Two-pass assembler: TA-format assembly text -> memory image (T-003, ADR-003/005).

Accepted source format (the course TA's test-program style, plus a few conveniences):

* ``#`` and ``;`` start a comment; blank lines are ignored.
* Numbers are **hexadecimal by default** (``10`` = 16). Prefixes ``0x``, ``0b``, ``0d``
  and a leading ``-`` are also accepted.
* ``.ORG addr`` sets the address of the next item.
* A line holding only a number (or ``.WORD n``) stores a raw 32-bit data word
  (used for the vectors at M[0..3]).
* Labels: ``name:`` alone or before an instruction; usable wherever a number is.
* Mnemonics and registers are case-insensitive; operands are separated by commas
  and/or spaces; memory operands are ``offset(Rn)``.
* ``#!`` lines carry test directives for the simulators (see :class:`Directives`).
"""

from __future__ import annotations

import re
from collections.abc import Callable
from dataclasses import dataclass, field
from pathlib import Path

from archp.isa import ADDR_MASK, MEM_WORDS, SPECS, WORD_MASK, Arg, Field, Op, disassemble, encode


class AsmError(ValueError):
    """Assembly error carrying the source location."""

    def __init__(self, line: int, msg: str, source: str = "<input>") -> None:
        super().__init__(f"{source}:{line}: {msg}")
        self.line = line


@dataclass
class Directives:
    """Simulation stimuli and checks embedded as ``#!`` comment lines.

    * ``#! in: 30 50 FFFF`` — values (hex) returned by successive IN instructions.
    * ``#! intr: 40 95`` — clock cycles (decimal) at which INTR.IN is pulsed.
    * ``#! expect: R1=30 SP=FFE Z=1 M[210]=5 OUT=30,50`` — final-state checks (hex).
    * ``#! max_cycles: 5000`` — simulation budget (decimal).
    """

    inputs: list[int] = field(default_factory=list)
    intr_cycles: list[int] = field(default_factory=list)
    expect: list[tuple[str, str]] = field(default_factory=list)
    max_cycles: int | None = None


@dataclass
class Program:
    words: dict[int, int]
    #: address -> (line number, source text)
    origin: dict[int, tuple[int, str]]
    labels: dict[str, int]
    directives: Directives
    #: addresses that hold instructions (vs. raw data words)
    code: set[int]

    def image(self) -> list[int]:
        img = [0] * MEM_WORDS
        for a, w in self.words.items():
            img[a] = w
        return img


_LABEL_DEF = re.compile(r"^\s*([A-Za-z_][A-Za-z0-9_.]*)\s*:")
_REG = re.compile(r"^[Rr]([0-7])$")
_MEM = re.compile(r"^(.*)\(\s*([A-Za-z0-9]+)\s*\)$")
_IDENT = re.compile(r"^[A-Za-z_][A-Za-z0-9_.]*$")


def parse_number(tok: str) -> int:
    """Parse a number token; bare digits are hexadecimal (TA convention)."""
    t = tok.strip()
    neg = t.startswith("-")
    if neg or t.startswith("+"):
        t = t[1:]
    low = t.lower()
    if low.startswith("0x"):
        v = int(t[2:], 16)
    elif low.startswith("0b"):
        v = int(t[2:], 2)
    elif low.startswith("0d"):
        v = int(t[2:], 10)
    else:
        v = int(t, 16)
    return -v if neg else v


def _strip_comment(line: str) -> str:
    cut = len(line)
    for ch in ("#", ";"):
        i = line.find(ch)
        if i != -1:
            cut = min(cut, i)
    return line[:cut]


def _parse_directive(text: str, d: Directives, lineno: int, src: str) -> None:
    body = text.strip()[2:].strip()
    if ":" not in body:
        raise AsmError(lineno, f"malformed directive '#! {body}'", src)
    key, _, rest = body.partition(":")
    key = key.strip().lower()
    toks = rest.replace(",", " ").split() if key != "expect" else rest.split()
    try:
        if key == "in":
            d.inputs.extend(parse_number(t) & WORD_MASK for t in toks)
        elif key == "intr":
            d.intr_cycles.extend(int(t, 10) for t in toks)
        elif key == "max_cycles":
            d.max_cycles = int(toks[0], 10)
        elif key == "expect":
            for t in toks:
                name, eq, val = t.partition("=")
                if not eq:
                    raise ValueError(t)
                d.expect.append((name.upper(), val))
        else:
            raise AsmError(lineno, f"unknown directive '{key}'", src)
    except (ValueError, IndexError) as e:
        raise AsmError(lineno, f"bad directive value in '#! {body}' ({e})", src) from e


@dataclass
class _Item:
    addr: int
    lineno: int
    text: str
    mnemonic: str | None  # None => data word
    args: list[str]


def _split_operands(s: str) -> list[str]:
    s = re.sub(r"\s*\(\s*", "(", s)
    s = re.sub(r"\s*\)", ")", s)
    return [t for t in re.split(r"[,\s]+", s.strip()) if t]


def assemble(text: str, source: str = "<input>") -> Program:
    directives = Directives()
    labels: dict[str, int] = {}
    items: list[_Item] = []
    loc = 0

    # ---- pass 1: addresses, labels, directives
    for lineno, raw in enumerate(text.splitlines(), start=1):
        if raw.strip().startswith("#!"):
            _parse_directive(raw, directives, lineno, source)
            continue
        line = _strip_comment(raw)
        while (m := _LABEL_DEF.match(line)) is not None:
            name = m.group(1)
            if name.upper() in SPECS or _REG.match(name):
                raise AsmError(lineno, f"label '{name}' clashes with a mnemonic/register", source)
            if name in labels:
                raise AsmError(lineno, f"duplicate label '{name}'", source)
            labels[name] = loc
            line = line[m.end() :]
        toks = line.split(None, 1)
        if not toks:
            continue
        head = toks[0]
        rest = toks[1] if len(toks) > 1 else ""
        up = head.upper()
        if up == ".ORG":
            try:
                loc = parse_number(rest.split()[0])
            except (ValueError, IndexError) as e:
                raise AsmError(lineno, f"bad .ORG operand '{rest.strip()}'", source) from e
            if not 0 <= loc <= ADDR_MASK:
                raise AsmError(lineno, f".ORG {loc:#x} outside 0..0xFFF", source)
            continue
        if up in SPECS:
            items.append(_Item(loc, lineno, raw.strip(), up, _split_operands(rest)))
        elif up in (".WORD", ".DATA"):
            items.append(_Item(loc, lineno, raw.strip(), None, _split_operands(rest)))
        else:
            # a bare number, or a lone label name (data word holding an address)
            lone_ident = not rest.strip() and _IDENT.match(head) is not None
            try:
                parse_number(head)
            except ValueError as e:
                if not lone_ident:
                    raise AsmError(lineno, f"unknown mnemonic '{head}'", source) from e
            items.append(_Item(loc, lineno, raw.strip(), None, _split_operands(line)))
        loc += 1

    # ---- pass 2: encode
    words: dict[int, int] = {}
    origin: dict[int, tuple[int, str]] = {}
    code: set[int] = set()

    def value(tok: str, lineno: int) -> int:
        if tok in labels:
            return labels[tok]
        if _REG.match(tok):
            raise AsmError(lineno, f"expected a number or label, got register '{tok}'", source)
        try:
            return parse_number(tok)
        except ValueError as e:
            if _IDENT.match(tok):
                raise AsmError(lineno, f"undefined label '{tok}'", source) from e
            raise AsmError(lineno, f"bad number '{tok}'", source) from e

    for it in items:
        if not 0 <= it.addr <= ADDR_MASK:
            raise AsmError(it.lineno, f"address {it.addr:#x} beyond memory (0..0xFFF)", source)
        if it.addr in words:
            prev = origin[it.addr][0]
            raise AsmError(it.lineno, f"address {it.addr:#05x} already used by line {prev}", source)
        if it.mnemonic is None:
            if len(it.args) != 1:
                raise AsmError(it.lineno, "a data word needs exactly one value", source)
            v = value(it.args[0], it.lineno)
            if not -(1 << 31) <= v <= WORD_MASK:
                raise AsmError(it.lineno, f"data word {v:#x} does not fit 32 bits", source)
            word = v & WORD_MASK
        else:
            word = _encode_instr(it, value, source)
            code.add(it.addr)
        words[it.addr] = word
        origin[it.addr] = (it.lineno, it.text)

    return Program(words, origin, labels, directives, code)


def _encode_instr(it: _Item, value: Callable[[str, int], int], source: str) -> int:
    spec = SPECS[it.mnemonic or ""]
    if len(it.args) != len(spec.operands):
        raise AsmError(
            it.lineno,
            f"{spec.op.name} takes {len(spec.operands)} operand(s): {spec.syntax}",
            source,
        )
    regs = {Field.RD: 0, Field.RA: 0, Field.RB: 0}
    imm = 0

    def reg(tok: str) -> int:
        m = _REG.match(tok)
        if m is None:
            raise AsmError(it.lineno, f"invalid register '{tok}' (R0..R7)", source)
        return int(m.group(1))

    def ranged(v: int, lo: int, hi: int, what: str) -> int:
        if not lo <= v <= hi:
            raise AsmError(it.lineno, f"{what} {v:#x} out of range [{lo:#x}, {hi:#x}]", source)
        return v & 0xFFFF

    for tok, opnd in zip(it.args, spec.operands, strict=True):
        if opnd.kind is Arg.REG:
            r = reg(tok)
            for f in opnd.fields:
                regs[f] = r
        elif opnd.kind is Arg.MEM:
            m = _MEM.match(tok)
            if m is None:
                raise AsmError(it.lineno, f"invalid memory operand '{tok}' (offset(Rn))", source)
            off_tok = m.group(1) or "0"
            imm = ranged(value(off_tok, it.lineno), -0x8000, 0xFFFF, "offset")
            for f in opnd.fields:
                regs[f] = reg(m.group(2))
        elif opnd.kind is Arg.SIMM:
            imm = ranged(value(tok, it.lineno), -0x8000, 0xFFFF, "immediate")
        elif opnd.kind is Arg.UIMM:
            imm = ranged(value(tok, it.lineno), 0, 0xFFFF, "unsigned immediate")
        elif opnd.kind is Arg.TARGET:
            imm = ranged(value(tok, it.lineno), 0, ADDR_MASK, "jump target")
        elif opnd.kind is Arg.INDEX:
            imm = ranged(value(tok, it.lineno), 0, 1, "INT index")
    return encode(Op(spec.op), regs[Field.RD], regs[Field.RA], regs[Field.RB], imm)


# ----------------------------------------------------------------- output formats


def mem_text(program: Program) -> str:
    """GHDL/ModelSim memory file: 4096 lines, 8 hex digits each, address 0 first."""
    return "".join(f"{w:08X}\n" for w in program.image())


def mif_text(program: Program) -> str:
    """Quartus Memory Initialization File (zero runs compressed into ranges)."""
    img = program.image()
    out = [
        "-- ARCHP memory image (generated by archp asm)",
        f"DEPTH = {MEM_WORDS};",
        "WIDTH = 32;",
        "ADDRESS_RADIX = HEX;",
        "DATA_RADIX = HEX;",
        "CONTENT",
        "BEGIN",
    ]
    a = 0
    while a < MEM_WORDS:
        b = a
        while b + 1 < MEM_WORDS and img[b + 1] == img[a] and img[a] == 0:
            b += 1
        if b > a:
            out.append(f"[{a:03X}..{b:03X}] : {img[a]:08X};")
        else:
            out.append(f"{a:03X} : {img[a]:08X};")
        a = b + 1
    out.append("END;")
    return "\n".join(out) + "\n"


def listing_text(program: Program) -> str:
    """Address / word / meaning / source, for reading waveforms during the demo."""
    lines = []
    for a in sorted(program.words):
        w = program.words[a]
        what = disassemble(w) if a in program.code else f".WORD {w:08X}"
        lineno, src = program.origin[a]
        lines.append(f"{a:03X}  {w:08X}  {what:<24} ; L{lineno}: {src}")
    return "\n".join(lines) + "\n"


def assemble_file(path: Path) -> Program:
    return assemble(path.read_text(encoding="utf-8"), source=str(path))


def stimulus_texts(program: Program) -> tuple[str, str]:
    """``.in`` (IN.PORT values, hex) and ``.intr`` (INTR cycles, decimal) for the testbench."""
    d = program.directives
    return (
        "".join(f"{v:08X}\n" for v in d.inputs),
        "".join(f"{c}\n" for c in sorted(d.intr_cycles)),
    )


def write_outputs(program: Program, stem: Path) -> list[Path]:
    """Write ``stem.mem/.mif/.lst`` and ``stem.in/.intr`` (testbench stimuli)."""
    stem.parent.mkdir(parents=True, exist_ok=True)
    ins, intr = stimulus_texts(program)
    texts = {
        ".mem": mem_text(program),
        ".mif": mif_text(program),
        ".lst": listing_text(program),
        ".in": ins,
        ".intr": intr,
    }
    paths = []
    for suffix, text in texts.items():
        p = stem.parent / (stem.name + suffix)
        p.write_text(text, encoding="utf-8")
        paths.append(p)
    return paths
