"""TC-211 + Quartus project consistency (TC-212 itself is run by the team).

* `ghdl --synth` of the Quartus top level must succeed for both predictor
  builds, infer the 4096 x 32 RAM and report no latch.
* The .qsf files must list exactly the RTL sources, in an order that compiles,
  and set nothing beyond device/top/files (default compiler settings).
"""

from __future__ import annotations

import re
from pathlib import Path

import pytest

from archp import REPO_ROOT, ghdl

from .conftest import requires_ghdl

Q = REPO_ROOT / "quartus"


def qsf_files(name: str) -> list[Path]:
    text = (Q / name).read_text()
    return [(Q / m).resolve() for m in re.findall(r"-name VHDL_FILE (\S+)", text)]


@pytest.mark.parametrize("name", ["archp.qsf", "archp_dynamic.qsf"])
def test_qsf_lists_every_rtl_file(name: str) -> None:
    assert set(qsf_files(name)) == {p.resolve() for p in ghdl.rtl_files()}


@pytest.mark.parametrize("name", ["archp.qsf", "archp_dynamic.qsf"])
def test_qsf_only_default_settings(name: str) -> None:
    allowed = {
        "FAMILY",
        "DEVICE",
        "TOP_LEVEL_ENTITY",
        "ORIGINAL_QUARTUS_VERSION",
        "PROJECT_OUTPUT_DIRECTORY",
        "VHDL_FILE",
    }
    text = (Q / name).read_text()
    used = set(re.findall(r"set_global_assignment -name (\w+)", text))
    assert used <= allowed, used - allowed
    params = re.findall(r"set_parameter -name (\w+) (\w+)", text)
    assert params == ([("G_DYNAMIC_BP", "true")] if "dynamic" in name else [])
    assert "5CSEMA5F31C6" in text


@requires_ghdl
def test_qsf_order_compiles(tmp_path: Path) -> None:
    ghdl.analyse(qsf_files("archp.qsf"), tmp_path)


@requires_ghdl
@pytest.mark.parametrize("dynamic", ["false", "true"])
def test_synthesis_no_latches(dynamic: str, tmp_path: Path) -> None:
    ghdl.analyse(ghdl.rtl_files(), tmp_path, top="processor_top")
    res = ghdl._call(
        [
            "--synth",
            ghdl.STD,
            f"--workdir={tmp_path}",
            f"-gG_DYNAMIC_BP={dynamic}",
            "processor_top",
        ],
        cwd=tmp_path,
    )
    assert res.returncode == 0, res.output[-3000:]
    log = res.output.lower()
    assert 'found ram "ram", width: 32 bits, depth: 4096' in log
    assert "latch" not in log
    assert "warning" not in log
