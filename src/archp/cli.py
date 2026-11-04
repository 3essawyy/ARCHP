"""`archp` command line. Sub-commands are added by later tasks (asm, golden, sim, check)."""

from __future__ import annotations

import argparse
import sys
from collections.abc import Sequence

from archp import __version__


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(prog="archp", description="ARCHP processor tools")
    p.add_argument("--version", action="version", version=f"archp {__version__}")
    p.add_subparsers(dest="cmd")
    return p


def main(argv: Sequence[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    if args.cmd is None:
        parser.print_help()
        return 0
    return 0


if __name__ == "__main__":
    sys.exit(main())
