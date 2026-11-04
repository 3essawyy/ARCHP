"""ARCHP tooling: assembler, golden ISA model, GHDL simulation runner."""

from pathlib import Path

__version__ = "0.1.0"

#: Repository root (src/archp/__init__.py -> repo).
REPO_ROOT = Path(__file__).resolve().parents[2]
