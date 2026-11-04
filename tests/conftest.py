from __future__ import annotations

import shutil
from pathlib import Path

import pytest

requires_ghdl = pytest.mark.skipif(shutil.which("ghdl") is None, reason="ghdl not installed")


@pytest.fixture(scope="session")
def rtl_build(tmp_path_factory: pytest.TempPathFactory) -> Path:
    """RTL + tb_processor analysed once per test worker."""
    if shutil.which("ghdl") is None:
        pytest.skip("ghdl not installed")
    from archp import sim

    return sim.build(tmp_path_factory.mktemp("rtl_build"))
