"""Run programs on the RTL (GHDL + tb_processor) and compare with the golden model.

ADR-013: the RTL dump (registers, SP, flags, OUT log, interrupt log, retired
count, full memory) must equal the golden model replayed with the same inputs
and with each hardware interrupt at the RTL's retired-instruction count.
"""

from __future__ import annotations

import tempfile
from dataclasses import dataclass, field
from pathlib import Path

from archp import REPO_ROOT, ghdl
from archp.assembler import Program, mem_text, stimulus_texts
from archp.golden import Golden, State

TB_TOP = "tb_processor"
DEFAULT_MAX_CYCLES = 20_000


@dataclass
class RtlResult:
    status: str = ""
    cycles: int = 0
    retired: int = 0
    pc: int = 0
    sp: int = 0
    flags: int = 0  # C N Z
    regs: list[int] = field(default_factory=lambda: [0] * 8)
    out: list[int] = field(default_factory=list)
    ints: list[int] = field(default_factory=list)
    mem: dict[int, int] = field(default_factory=dict)
    log: str = ""


def tb_sources() -> list[Path]:
    return [*ghdl.rtl_files(), REPO_ROOT / "tb/tb_util_pkg.vhd", REPO_ROOT / "tb/tb_processor.vhd"]


def build(workdir: Path) -> Path:
    """Analyse RTL + testbench once into `workdir` (reused by many runs)."""
    ghdl.analyse(tb_sources(), workdir, top=TB_TOP)
    return workdir


def parse_dump(text: str) -> RtlResult:
    r = RtlResult()
    for line in text.splitlines():
        parts = line.split()
        if not parts:
            continue
        key = parts[0]
        if key == "STATUS":
            r.status = parts[1]
        elif key == "CYCLES":
            r.cycles = int(parts[1])
        elif key == "RETIRED":
            r.retired = int(parts[1])
        elif key == "PC":
            r.pc = int(parts[1], 16)
        elif key == "SP":
            r.sp = int(parts[1], 16)
        elif key == "FLAGS":
            r.flags = int(parts[1], 16) & 7
        elif key.startswith("R") and key[1:].isdigit():
            r.regs[int(key[1:])] = int(parts[1], 16)
        elif key == "OUT":
            r.out.append(int(parts[1], 16))
        elif key == "INT":
            r.ints.append(int(parts[1]))
        elif key == "M":
            r.mem[int(parts[1], 16)] = int(parts[2], 16)
    return r


def run_rtl(
    program: Program,
    builddir: Path,
    *,
    dynamic: bool = False,
    intr_cycles: list[int] | None = None,
    max_cycles: int | None = None,
    wave: Path | None = None,
) -> RtlResult:
    d = program.directives
    with tempfile.TemporaryDirectory(prefix="archp-run-") as tmp:
        t = Path(tmp)
        (t / "prog.mem").write_text(mem_text(program))
        ins, intr_text = stimulus_texts(program)
        if intr_cycles is not None:
            intr_text = "".join(f"{c}\n" for c in sorted(intr_cycles))
        (t / "in.txt").write_text(ins)
        (t / "intr.txt").write_text(intr_text)
        generics: dict[str, str | int | bool] = {
            "G_PROGRAM": str(t / "prog.mem"),
            "G_INPUTS": str(t / "in.txt"),
            "G_INTR": str(t / "intr.txt"),
            "G_DUMP": str(t / "dump.txt"),
            "G_MAX_CYCLES": max_cycles or d.max_cycles or DEFAULT_MAX_CYCLES,
            "G_DYNAMIC_BP": dynamic,
        }
        extra = [f"--wave={wave}"] if wave else []
        res = ghdl.run(TB_TOP, builddir, generics, extra)
        if res.returncode != 0 or not (t / "dump.txt").exists():
            raise ghdl.GhdlError(f"simulation failed:\n{res.output[-4000:]}")
        out = parse_dump((t / "dump.txt").read_text())
        out.log = res.output
        return out


def golden_for(program: Program, rtl: RtlResult) -> State:
    """Golden run with the same inputs and the RTL's interrupt points."""
    g = Golden(program.image(), program.directives.inputs, rtl.ints)
    return g.run()


def compare(g: State, r: RtlResult) -> list[str]:
    diffs: list[str] = []
    if r.status != "HALTED":
        diffs.append(f"RTL did not halt (status {r.status} after {r.cycles} cycles)")
    for i in range(8):
        if g.regs[i] != r.regs[i]:
            diffs.append(f"R{i}: golden {g.regs[i]:08X} rtl {r.regs[i]:08X}")
    if g.sp != r.sp:
        diffs.append(f"SP: golden {g.sp:03X} rtl {r.sp:03X}")
    if g.flags != r.flags:
        diffs.append(f"flags CNZ: golden {g.flags:03b} rtl {r.flags:03b}")
    if g.pc != r.pc:
        diffs.append(f"halt PC: golden {g.pc:03X} rtl {r.pc:03X}")
    if g.out != r.out:
        diffs.append(f"OUT: golden {[hex(v) for v in g.out]} rtl {[hex(v) for v in r.out]}")
    if g.retired != r.retired:
        diffs.append(f"retired: golden {g.retired} rtl {r.retired}")
    if g.hw_ints != r.ints:
        diffs.append(f"interrupts: golden {g.hw_ints} rtl {r.ints}")
    gm = {a: w for a, w in enumerate(g.mem) if w}
    for a in sorted(set(gm) | set(r.mem)):
        if gm.get(a, 0) != r.mem.get(a, 0):
            diffs.append(f"M[{a:03X}]: golden {gm.get(a, 0):08X} rtl {r.mem.get(a, 0):08X}")
    return diffs
