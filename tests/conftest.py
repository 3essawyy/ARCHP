from __future__ import annotations

import shutil

import pytest

requires_ghdl = pytest.mark.skipif(shutil.which("ghdl") is None, reason="ghdl not installed")
