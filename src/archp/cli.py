"""`archp` command line: asm (T-003), golden (T-004); sim and check are added by T-006."""

from __future__ import annotations

import argparse
import sys
from collections.abc import Sequence
from pathlib import Path

from archp import __version__
from archp.assembler import AsmError, assemble_file, write_outputs
from archp.golden import Golden, State, check_expect


def _cmd_asm(args: argparse.Namespace) -> int:
    src = Path(args.source)
    try:
        prog = assemble_file(src)
    except AsmError as e:
        print(f"error: {e}", file=sys.stderr)
        return 1
    stem = Path(args.output) if args.output else src.with_suffix("")
    for p in write_outputs(prog, stem):
        print(f"wrote {p}")
    print(f"{len(prog.words)} words ({len(prog.code)} instructions)")
    return 0


def format_state(s: State) -> str:
    regs = " ".join(f"R{i}={v:08X}" for i, v in enumerate(s.regs))
    outs = ",".join(f"{v:X}" for v in s.out)
    return (
        f"{regs}\nPC={s.pc:03X} SP={s.sp:03X} Z={s.z} N={s.n} C={s.c} "
        f"retired={s.retired} hw_ints={s.hw_ints}\nOUT=[{outs}]"
    )


def _cmd_golden(args: argparse.Namespace) -> int:
    try:
        prog = assemble_file(Path(args.source))
    except AsmError as e:
        print(f"error: {e}", file=sys.stderr)
        return 1
    d = prog.directives
    g = Golden(prog.image(), d.inputs, args.intr or [])
    st = g.run()
    print(format_state(st))
    errors = check_expect(st, d.expect)
    for err in errors:
        print(f"EXPECT FAIL {err}")
    print("expectations: " + ("FAIL" if errors else f"{len(d.expect)} OK"))
    return 1 if errors else 0


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(prog="archp", description="ARCHP processor tools")
    p.add_argument("--version", action="version", version=f"archp {__version__}")
    sub = p.add_subparsers(dest="cmd")
    a = sub.add_parser("asm", help="assemble a program into .mem/.mif/.lst")
    a.add_argument("source", help="assembly file (.asm / .txt)")
    a.add_argument("-o", "--output", help="output path stem (default: next to the source)")
    a.set_defaults(func=_cmd_asm)
    g = sub.add_parser("golden", help="run a program on the golden ISA model")
    g.add_argument("source")
    g.add_argument(
        "--intr", type=int, nargs="*", help="retired-instruction counts at which INTR fires"
    )
    g.set_defaults(func=_cmd_golden)
    return p


def main(argv: Sequence[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    if args.cmd is None:
        parser.print_help()
        return 0
    rc: int = args.func(args)
    return rc


if __name__ == "__main__":
    sys.exit(main())
