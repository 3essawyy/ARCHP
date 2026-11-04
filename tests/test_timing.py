"""Hazard penalties measured on the RTL match HLD §6 (cycle deltas, not absolutes).

Each case runs two programs that differ only in the hazard under test; trailing
NOPs make sure the effect is not hidden by HLT stopping the fetch early.
"""

from __future__ import annotations

from pathlib import Path

import pytest

from archp import sim
from archp.assembler import assemble

HEAD = ".ORG 0\n10\n.ORG 10\nLDM R1, 100\nLDM R3, 1\n"
TAIL = "\nNOP\nNOP\nNOP\nNOP\nNOP\nNOP\nHLT\n.ORG 300\nF: RET\n"


def cycles(body: str, build: Path) -> int:
    return sim.run_rtl(assemble(HEAD + body + TAIL), build).cycles


@pytest.mark.parametrize(
    ("hazard", "reference", "penalty"),
    [
        # load-use (HLD 6.2): data only exists in WB
        ("LDD R2, 0(R1)\nADD R4, R2, R2", "LDD R2, 0(R1)\nADD R4, R3, R3", 2),
        ("LDD R2, 0(R1)\nNOP\nADD R4, R2, R2", "LDD R2, 0(R1)\nNOP\nADD R4, R3, R3", 1),
        ("LDD R2, 0(R1)\nNOP\nNOP\nADD R4, R2, R2", "LDD R2, 0(R1)\nNOP\nNOP\nADD R4, R3, R3", 0),
        ("POP R2\nINC R2", "POP R2\nINC R3", 2),
        # ALU results are forwarded: no penalty
        ("ADD R2, R3, R3\nADD R4, R2, R2", "ADD R2, R3, R3\nADD R4, R3, R3", 0),
        # structural (HLD 6.1): memory access steals one fetch slot
        ("STD R3, 0(R1)", "NOP", 1),
        ("PUSH R3\nPOP R4", "NOP\nNOP", 2),
        # SWAP = two micro-ops
        ("SWAP R2, R3", "MOV R2, R3", 1),
        # control hazards (HLD 6.3): taken JZ resolved in EX2 flushes 2;
        # JMP/CALL redirect in decode cost 0; RET waits for the popped PC (4)
        ("SUB R2, R3, R3\nJZ L\nL: NOP", "ADD R2, R3, R3\nJZ L\nL: NOP", 2),
        ("JMP L\nL: NOP", "NOP\nNOP", 0),
        ("CALL F", "NOP\nNOP", 4),
    ],
    ids=[
        "load-use-d1",
        "load-use-d2",
        "load-use-d3",
        "pop-use",
        "alu-raw",
        "store",
        "push-pop",
        "swap",
        "jz-taken",
        "jmp",
        "call-ret",
    ],
)
def test_penalty(hazard: str, reference: str, penalty: int, rtl_build: Path) -> None:
    assert cycles(hazard, rtl_build) - cycles(reference, rtl_build) == penalty
