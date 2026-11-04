"""TC-207: hardware interrupts and INT/RTI, including corner cases (ADR-007)."""

from __future__ import annotations

from pathlib import Path

import pytest

from archp import REPO_ROOT, fuzz, sim
from archp.assembler import assemble, assemble_file
from archp.golden import check_expect

PROG = assemble_file(REPO_ROOT / "programs/interrupt.asm")


def run_and_compare(prog: object, build: Path, intr: list[int]) -> sim.RtlResult:
    r = sim.run_rtl(prog, build, intr_cycles=intr)  # type: ignore[arg-type]
    g = sim.golden_for(prog, r)  # type: ignore[arg-type]
    diffs = sim.compare(g, r)
    assert diffs == [], f"INTR at {intr}:\n" + "\n".join(diffs)
    return r


def test_no_interrupt_baseline(rtl_build: Path) -> None:
    r = run_and_compare(PROG, rtl_build, [])
    assert r.ints == []
    assert r.regs[6] == 0


# one pulse at every cycle of the program: lands on branches, flushes, stalls,
# CALL/RET waits, memory conflicts, the ISR itself is never re-entered
@pytest.mark.parametrize("cycle", range(1, 125, 1))
def test_single_pulse_sweep(cycle: int, rtl_build: Path) -> None:
    r = run_and_compare(PROG, rtl_build, [cycle])
    if cycle < r.cycles - 12:  # well before HLT: must be taken exactly once
        assert len(r.ints) == 1, f"pulse at {cycle}: {r.ints}"
        assert r.regs[6] == 1
    assert len(r.ints) <= 1


def test_held_high_is_one_interrupt(rtl_build: Path) -> None:
    r = run_and_compare(PROG, rtl_build, [20, 21, 22, 23, 24, 25])
    assert len(r.ints) == 1


def test_three_interrupts_expectations(rtl_build: Path) -> None:
    r = run_and_compare(PROG, rtl_build, PROG.directives.intr_cycles)
    g = sim.golden_for(PROG, r)
    assert len(r.ints) == 3
    assert check_expect(g, PROG.directives.expect) == []


def test_back_to_back_pulses_nest(rtl_build: Path) -> None:
    # second edge arrives after the first was acknowledged: nested, both served
    r = run_and_compare(PROG, rtl_build, [30, 33])
    assert len(r.ints) == 2
    assert r.regs[6] == 2


def test_edges_before_acknowledge_merge(rtl_build: Path) -> None:
    # documented limitation (ADR-007): a 1-bit request latch merges an edge that
    # arrives before the pending request is acknowledged (push micro-op in EX2)
    r = run_and_compare(PROG, rtl_build, [30, 32])
    assert len(r.ints) == 1


def test_interrupt_after_hlt_is_ignored(rtl_build: Path) -> None:
    prog = assemble(".ORG 0\n10\n.ORG 1\n20\n.ORG 10\nHLT\n.ORG 20\nINC R6\nRTI\n")
    r = run_and_compare(prog, rtl_build, [8, 9])
    assert r.ints == []
    assert r.status == "HALTED"


@pytest.mark.parametrize("seed", range(30))
def test_fuzz_with_interrupts(seed: int, rtl_build: Path) -> None:
    src = fuzz.generate(2000 + seed, length=70, branches=True, calls=True, sw_int=True, hw_int=True)
    prog = assemble(src)
    cycles = sorted({(seed * 37 + k * 53) % 220 + 5 for k in range(3)})
    run_and_compare(prog, rtl_build, cycles)
