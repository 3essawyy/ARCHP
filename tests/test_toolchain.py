"""T-002: the GHDL toolchain works and failures are visible."""

from __future__ import annotations

from pathlib import Path

from archp import REPO_ROOT, ghdl
from archp.cli import main

from .conftest import requires_ghdl


@requires_ghdl
def test_ghdl_smoke_passes(tmp_path: Path) -> None:
    ghdl.analyse([REPO_ROOT / "tb/unit/tb_smoke.vhd"], tmp_path)
    res = ghdl.run("tb_smoke", tmp_path)
    assert res.returncode == 0, res.output
    assert "TB_PASS" in res.output


@requires_ghdl
def test_ghdl_reports_assertion_failure(tmp_path: Path) -> None:
    ghdl.analyse([REPO_ROOT / "tb/unit/tb_smoke.vhd"], tmp_path)
    res = ghdl.run("tb_smoke", tmp_path, {"G_FAIL": True})
    assert res.returncode != 0
    assert "forced failure" in res.output


def test_cli_runs() -> None:
    assert main([]) == 0
