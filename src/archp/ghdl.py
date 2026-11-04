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


def _call(args: Sequence[str], cwd: Path, timeout: float = 600) -> RunResult:
    try:
        proc = subprocess.run(
            [ghdl_exe(), *args],
            cwd=cwd,
            capture_output=True,
            text=True,
            check=False,
            timeout=timeout,
        )
    except subprocess.TimeoutExpired as e:
        raise GhdlError(f"ghdl {' '.join(args[:3])} timed out after {timeout}s") from e
    return RunResult(proc.returncode, proc.stdout + proc.stderr)


def analyse(files: Sequence[Path], workdir: Path, top: str | None = None) -> None:
    """Import `files` into the `work` library inside `workdir` and build them.

    With `top`, GHDL's make (`-m`) analyses everything `top` needs in dependency
    order; without it, files are analysed in the given order.
    """
    workdir.mkdir(parents=True, exist_ok=True)
    if top is None:
        for f in files:
            res = _call(["-a", STD, f"--workdir={workdir}", str(f)], cwd=workdir)
            if res.returncode != 0:
                raise GhdlError(f"analysis failed for {f}:\n{res.output}")
        return
    res = _call(["-i", STD, f"--workdir={workdir}", *map(str, files)], cwd=workdir)
    if res.returncode != 0:
        raise GhdlError(f"import failed:\n{res.output}")
    res = _call(["-m", STD, f"--workdir={workdir}", top], cwd=workdir)
    if res.returncode != 0:
        raise GhdlError(f"build of {top} failed:\n{res.output}")


def run(
    top: str,
    workdir: Path,
    generics: Mapping[str, str | int | bool] | None = None,
    extra: Sequence[str] = (),
    timeout: float = 600,
) -> RunResult:
    """Elaborate and run `top` in one step (never raises on a failed assertion).

    A single ``--elab-run`` matters: elaboration evaluates generics-dependent
    constants (e.g. file loaders), so it must see the real generic values.
    """
    gargs = []
    for k, v in (generics or {}).items():
        if isinstance(v, bool):
            v = "true" if v else "false"
        gargs.append(f"-g{k}={v}")
    return _call(
        ["--elab-run", STD, f"--workdir={workdir}", top, *gargs, "--assert-level=error", *extra],
        cwd=workdir,
        timeout=timeout,
    )


def rtl_files() -> list[Path]:
    """All synthesizable sources (order does not matter with `analyse(..., top=...)`)."""
    return sorted((REPO_ROOT / "rtl").rglob("*.vhd"))
