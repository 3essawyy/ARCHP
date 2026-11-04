"""Every relative Markdown link in the repo resolves (T-001 feedback, ADR-001)."""

from __future__ import annotations

import re

from archp import REPO_ROOT

_SKIP_DIRS = {".git", ".venv", "node_modules", "build"}


def _broken_links() -> list[str]:
    broken: list[str] = []
    for md in REPO_ROOT.rglob("*.md"):
        if _SKIP_DIRS.intersection(md.relative_to(REPO_ROOT).parts) or md.name == "_TEMPLATE.md":
            continue
        text = re.sub(r"```.*?```", "", md.read_text(encoding="utf-8"), flags=re.S)
        for m in re.finditer(r"\]\(([^)\s]+)\)", text):
            link = m.group(1)
            if re.match(r"^[a-z]+:", link) or link.startswith("#"):
                continue
            if not (md.parent / link.split("#")[0]).exists():
                broken.append(f"{md.relative_to(REPO_ROOT)} -> {link}")
    return broken


def test_no_broken_relative_links() -> None:
    assert _broken_links() == []
