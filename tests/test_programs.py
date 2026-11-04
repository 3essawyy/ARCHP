"""TC-201…TC-209: every program on the RTL equals the golden model (ADR-013)."""

from __future__ import annotations

from pathlib import Path

import pytest

from archp import REPO_ROOT, fuzz, sim
from archp.assembler import assemble, assemble_file
from archp.golden import check_expect

PROGRAMS = sorted((REPO_ROOT / "programs").glob("*.asm"))
# Features delivered by later tasks: strict xfail until then (must start passing).
PENDING = {
    "int_sw": "INT/RTI (T-008)",
}


def _check(prog_src: Path | str, build: Path, dynamic: bool = False) -> None:
    prog = assemble_file(prog_src) if isinstance(prog_src, Path) else assemble(prog_src)
    r = sim.run_rtl(prog, build, dynamic=dynamic)
    g = sim.golden_for(prog, r)
    diffs = sim.compare(g, r) + [f"expect {e}" for e in check_expect(g, prog.directives.expect)]
    assert diffs == [], "\n".join(diffs)


@pytest.mark.parametrize(
    "path",
    [
        pytest.param(p, marks=pytest.mark.xfail(strict=True, reason=PENDING[p.stem]))
        if p.stem in PENDING
        else p
        for p in PROGRAMS
    ],
    ids=lambda p: p.stem,
)
def test_program_static(path: Path, rtl_build: Path) -> None:
    _check(path, rtl_build)


@pytest.mark.parametrize("seed", range(40))
def test_fuzz_straight_line(seed: int, rtl_build: Path) -> None:
    _check(fuzz.generate(seed, length=70), rtl_build)


@pytest.mark.parametrize("seed", range(40))
def test_fuzz_control_flow(seed: int, rtl_build: Path) -> None:
    _check(fuzz.generate(1000 + seed, length=70, branches=True, calls=True), rtl_build)
