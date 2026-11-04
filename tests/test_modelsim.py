"""TC-213 (automated part): the ModelSim do-files are consistent with the sources.

ModelSim itself is run by the team (SG-004). Here we check what can break silently:
compile.do lists every RTL/TB file in a valid dependency order (compiled with GHDL
in exactly that order), and wave.do only names signals that exist.
"""

from __future__ import annotations

import re
from pathlib import Path

from archp import REPO_ROOT, ghdl

from .conftest import requires_ghdl

DO = REPO_ROOT / "sim/modelsim"


def compile_do_files() -> list[Path]:
    text = (DO / "compile.do").read_text()
    files = []
    for m in re.finditer(r"vcom -93 -work work \$(RTL|TB)/(\S+)", text):
        base = REPO_ROOT / ("rtl" if m.group(1) == "RTL" else "tb")
        files.append(base / m.group(2))
    return files


def test_compile_do_lists_every_source() -> None:
    listed = {p.resolve() for p in compile_do_files()}
    expected = {p.resolve() for p in ghdl.rtl_files()}
    expected |= {
        (REPO_ROOT / "tb/tb_util_pkg.vhd").resolve(),
        (REPO_ROOT / "tb/tb_processor.vhd").resolve(),
    }
    assert listed == expected


@requires_ghdl
def test_compile_do_order_is_valid(tmp_path: Path) -> None:
    ghdl.analyse(compile_do_files(), tmp_path)  # plain -a in the listed order


def test_wave_do_signals_exist() -> None:
    tb = (REPO_ROOT / "tb/tb_processor.vhd").read_text()
    wave = (DO / "wave.do").read_text()
    names = set(re.findall(r"/tb_processor/(\w+)", wave))
    assert names == {
        "clk",
        "rst",
        "intr",
        "in_port",
        "out_port",
        "dbg_pc",
        "dbg_sp",
        "dbg_flags",
        "dbg_regs",
    }
    for n in names:
        assert re.search(rf"signal\s+[\w\s,]*\b{n}\b", tb), n
    assert all(f"dbg_regs({i})" in wave for i in range(8))


def test_run_do_uses_existing_generics() -> None:
    tb = (REPO_ROOT / "tb/tb_processor.vhd").read_text()
    for g in re.findall(r"-g(\w+)=", (DO / "run.do").read_text()):
        assert g in tb, g
