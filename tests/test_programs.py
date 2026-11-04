"""TC-201…TC-209: every program on the RTL equals the golden model (ADR-013)."""

from __future__ import annotations

from pathlib import Path

import pytest

from archp import REPO_ROOT, fuzz, sim
from archp.assembler import assemble, assemble_file
from archp.golden import check_expect

PROGRAMS = sorted((REPO_ROOT / "programs").glob("*.asm"))


def _check(prog_src: Path | str, build: Path, dynamic: bool = False) -> None:
    prog = assemble_file(prog_src) if isinstance(prog_src, Path) else assemble(prog_src)
    r = sim.run_rtl(prog, build, dynamic=dynamic)
    g = sim.golden_for(prog, r)
    diffs = sim.compare(g, r) + [f"expect {e}" for e in check_expect(g, prog.directives.expect)]
    assert diffs == [], "\n".join(diffs)


MODES = [pytest.param(False, id="static"), pytest.param(True, id="dynamic")]


@pytest.mark.parametrize("dynamic", MODES)
@pytest.mark.parametrize("path", PROGRAMS, ids=lambda p: p.stem)
def test_program(path: Path, dynamic: bool, rtl_build: Path) -> None:
    _check(path, rtl_build, dynamic)


@pytest.mark.parametrize("dynamic", MODES)
@pytest.mark.parametrize("seed", range(40))
def test_fuzz_straight_line(seed: int, dynamic: bool, rtl_build: Path) -> None:
    _check(fuzz.generate(seed, length=70), rtl_build, dynamic)


@pytest.mark.parametrize("dynamic", MODES)
@pytest.mark.parametrize("seed", range(40))
def test_fuzz_control_flow(seed: int, dynamic: bool, rtl_build: Path) -> None:
    _check(fuzz.generate(1000 + seed, length=70, branches=True, calls=True), rtl_build, dynamic)


def test_dynamic_predictor_speeds_up_loops(rtl_build: Path) -> None:
    # TC-210: 31 taken backward jumps; static pays 2 cycles each, the BTB only
    # mispredicts the first taken jump and the loop exit (31*2 - 2*2 = 58 saved)
    prog = assemble_file(REPO_ROOT / "programs/loop.asm")
    static = sim.run_rtl(prog, rtl_build).cycles
    dynamic = sim.run_rtl(prog, rtl_build, dynamic=True).cycles
    assert static - dynamic == 58


@pytest.mark.parametrize("dynamic", MODES)
@pytest.mark.parametrize("seed", range(40))
def test_fuzz_loops(seed: int, dynamic: bool, rtl_build: Path) -> None:
    src = fuzz.generate(3000 + seed, length=70, branches=True, calls=True, loops=True)
    _check(src, rtl_build, dynamic)
