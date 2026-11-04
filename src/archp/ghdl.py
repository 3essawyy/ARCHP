"""Thin GHDL driver (ADR-002): analyse VHDL-93 sources, elaborate and run a testbench.

Every call uses its own work directory so parallel test workers never share
GHDL library files.
"""

from __future__ import annotations

import shutil
import subprocess
from collections.abc import Mapping, Sequence
from dataclasses import dataclass
from pathlib import Path

from archp import REPO_ROOT

STD = "--std=93c"


class GhdlError(RuntimeError):
    """GHDL failed to analyse, elaborate or run."""


@dataclass(frozen=True)
class RunResult:
    returncode: int
    output: str


def ghdl_exe() -> str:
    exe = shutil.which("ghdl")
    if exe is None:
        raise GhdlError("ghdl not found on PATH (see docs/SystemGuides/SG-001-setup-and-checks.md)")
    return exe


def _call(args: Sequence[str], cwd: Path) -> RunResult:
    proc = subprocess.run([ghdl_exe(), *args], cwd=cwd, capture_output=True, text=True, check=False)
    return RunResult(proc.returncode, proc.stdout + proc.stderr)


def analyse(files: Sequence[Path], workdir: Path) -> None:
    """Analyse files in order into the `work` library inside `workdir`."""
    workdir.mkdir(parents=True, exist_ok=True)
    for f in files:
        res = _call(["-a", STD, f"--workdir={workdir}", str(f)], cwd=workdir)
        if res.returncode != 0:
            raise GhdlError(f"analysis failed for {f}:\n{res.output}")


def run(
    top: str,
    workdir: Path,
    generics: Mapping[str, str | int | bool] | None = None,
    extra: Sequence[str] = (),
) -> RunResult:
    """Elaborate and run `top`; returns the combined output (never raises on assert)."""
    gargs = []
    for k, v in (generics or {}).items():
        if isinstance(v, bool):
            v = "true" if v else "false"
        gargs.append(f"-g{k}={v}")
    elab = _call(["-e", STD, f"--workdir={workdir}", top], cwd=workdir)
    if elab.returncode != 0:
        raise GhdlError(f"elaboration of {top} failed:\n{elab.output}")
    return _call(
        ["-r", STD, f"--workdir={workdir}", top, *gargs, "--assert-level=error", *extra],
        cwd=workdir,
    )


def rtl_files() -> list[Path]:
    """Synthesizable sources in dependency order (package first, top last)."""
    order = ["pkg", "memory", "decode", "execute", "pipeline", "fetch", "core", "top"]
    rtl = REPO_ROOT / "rtl"
    files: list[Path] = []
    for d in order:
        files.extend(sorted((rtl / d).glob("*.vhd")))
    return files
