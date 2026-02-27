#!/usr/bin/env python3
"""Validate Markdown rules required by this Pandoc/XeLaTeX rendering workflow."""

from __future__ import annotations

import re
import sys
from pathlib import Path
from typing import List, Set, Tuple

FENCE_RE = re.compile(r"^\s*```(.*)$")
LIST_RE = re.compile(r"^([ \t]*)([-+*]|\d+\.)\s+")
IMAGE_RE = re.compile(r"^\s*!\[[^\]]*\]\(([^)]+)\)\s*$")
ALIGN_CELL_RE = re.compile(r"^:?-{3,}:?$")


def is_table_row(line: str) -> bool:
    stripped = line.strip()
    if not stripped or "|" not in stripped:
        return False
    return stripped.startswith("|") or stripped.endswith("|") or " | " in stripped


def split_table_cells(line: str) -> List[str]:
    return [cell.strip() for cell in line.strip().strip("|").split("|")]


def is_alignment_row(line: str) -> bool:
    cells = split_table_cells(line)
    if not cells:
        return False
    return all(bool(ALIGN_CELL_RE.fullmatch(cell)) for cell in cells)


def is_list_line(line: str) -> bool:
    return bool(LIST_RE.match(line))


def valid_nested_indent(indent: str) -> bool:
    if not indent:
        return True
    if set(indent) <= {"\t"}:
        return True
    return set(indent) <= {" "} and len(indent) % 4 == 0


def collect_code_blocks(lines: List[str]) -> Tuple[Set[int], List[str]]:
    code_lines: Set[int] = set()
    errors: List[str] = []
    in_block = False
    open_index = -1

    for i, line in enumerate(lines):
        match = FENCE_RE.match(line)
        if not match:
            continue

        info = match.group(1).strip()
        if not in_block:
            if not info:
                errors.append(
                    f"line {i + 1}: fenced code block must declare language "
                    "(for example: ```python)."
                )
            if i > 0 and lines[i - 1].strip():
                errors.append(
                    f"line {i + 1}: code block must have one blank line above it."
                )
            in_block = True
            open_index = i
        else:
            if i + 1 < len(lines) and lines[i + 1].strip():
                errors.append(
                    f"line {i + 1}: code block must have one blank line below it."
                )
            for idx in range(open_index, i + 1):
                code_lines.add(idx)
            in_block = False
            open_index = -1

    if in_block:
        errors.append(f"line {open_index + 1}: code block is not closed.")

    return code_lines, errors


def check_images(lines: List[str], code_lines: Set[int]) -> List[str]:
    errors: List[str] = []
    for i, line in enumerate(lines):
        if i in code_lines:
            continue
        match = IMAGE_RE.match(line)
        if not match:
            continue

        path = match.group(1).strip()
        if not path.startswith("images/"):
            errors.append(
                f"line {i + 1}: image path must be relative and start with 'images/'."
            )
        if i == 0 or lines[i - 1].strip():
            errors.append(f"line {i + 1}: image must have one blank line above it.")
        if i + 1 >= len(lines) or lines[i + 1].strip():
            errors.append(f"line {i + 1}: image must have one blank line below it.")
    return errors


def check_lists(lines: List[str], code_lines: Set[int]) -> List[str]:
    errors: List[str] = []
    for i, line in enumerate(lines):
        if i in code_lines:
            continue
        match = LIST_RE.match(line)
        if not match:
            continue

        indent = match.group(1)
        marker = match.group(2)

        if marker in {"*", "+"}:
            errors.append(
                f"line {i + 1}: unordered list must use '-' instead of '{marker}'."
            )

        if indent and not valid_nested_indent(indent):
            errors.append(
                f"line {i + 1}: nested list indentation must be 4 spaces or 1 tab."
            )

        if i > 0 and lines[i - 1].strip() and not is_list_line(lines[i - 1]):
            errors.append(
                f"line {i + 1}: list block must have one blank line above the first list item."
            )
    return errors


def check_tables(lines: List[str], code_lines: Set[int]) -> List[str]:
    errors: List[str] = []
    i = 0
    while i < len(lines):
        if i in code_lines:
            i += 1
            continue

        if i + 1 < len(lines) and is_table_row(lines[i]) and is_alignment_row(lines[i + 1]):
            j = i + 2
            while j < len(lines) and j not in code_lines and is_table_row(lines[j]):
                j += 1

            if j >= len(lines) or not lines[j].startswith("Table:"):
                errors.append(
                    f"line {j + 1 if j < len(lines) else len(lines)}: "
                    "table must be followed immediately by 'Table: <caption>'."
                )
                i = j
                continue

            caption = lines[j][len("Table:") :].strip()
            if not caption:
                errors.append(f"line {j + 1}: table caption text is required after 'Table:'.")

            if j + 1 < len(lines) and lines[j + 1].strip():
                errors.append(f"line {j + 1}: table caption must be followed by one blank line.")

            i = j + 1
            continue

        i += 1

    return errors


def run(path: Path) -> int:
    lines = path.read_text(encoding="utf-8").splitlines()
    errors: List[str] = []

    code_lines, code_errors = collect_code_blocks(lines)
    errors.extend(code_errors)
    errors.extend(check_images(lines, code_lines))
    errors.extend(check_lists(lines, code_lines))
    errors.extend(check_tables(lines, code_lines))

    if errors:
        print(f"[fail] {path}")
        for err in errors:
            print(f" - {err}")
        return 1

    print(f"[ok] {path}")
    return 0


def main() -> int:
    if len(sys.argv) != 2 or sys.argv[1] in {"-h", "--help"}:
        print("Usage: markdown_preflight.py <input.md>")
        return 1 if len(sys.argv) != 2 else 0

    md_path = Path(sys.argv[1])
    if not md_path.exists() or not md_path.is_file():
        print(f"[error] file not found: {md_path}", file=sys.stderr)
        return 1

    return run(md_path)


if __name__ == "__main__":
    raise SystemExit(main())
