#!/usr/bin/env python3
"""Validate the ANCX777 playbook sources.

Checks performed:
  * Configuration/main.yml parses, with AME's !action tags treated as plain data
  * every ``option:`` referenced by an action is declared in playbook.conf
  * every declared option is used by at least one action

Exits non-zero on failure so CI can gate on it.

Usage:  python src/dependencies/validate.py
"""

from __future__ import annotations

import sys
import xml.etree.ElementTree as ET
from pathlib import Path

try:
    import yaml
except ImportError:  # pragma: no cover
    sys.exit("PyYAML is required: pip install pyyaml")

PLAYBOOK_DIR = Path(__file__).resolve().parents[1] / "playbook"
CONF_FILE = PLAYBOOK_DIR / "playbook.conf"
MAIN_FILE = PLAYBOOK_DIR / "Configuration" / "main.yml"

# Options whose correct behaviour is to run nothing at all.
#   keep-edge      - Edge removal deletes files, so it cannot be undone.
#   keep-wallpaper - keeping the current wallpaper means changing nothing.
#   keep-branding  - keeping Windows' own registered organization means changing nothing.
INTENTIONAL_NOOPS = {"keep-edge", "keep-wallpaper", "keep-branding"}


class AmeLoader(yaml.SafeLoader):
    """SafeLoader that keeps unknown `!action` tags as ordinary mappings."""


def _construct_tagged(loader: AmeLoader, tag_suffix: str, node: yaml.Node):
    if isinstance(node, yaml.MappingNode):
        return loader.construct_mapping(node, deep=True)
    if isinstance(node, yaml.SequenceNode):
        return loader.construct_sequence(node, deep=True)
    return loader.construct_scalar(node)


AmeLoader.add_multi_constructor("!", _construct_tagged)


def declared_options() -> set[str]:
    tree = ET.parse(CONF_FILE)
    return {el.text.strip() for el in tree.iter("Name") if el.text and el.text.strip()}


def collect_options(node, out: set[str]) -> None:
    if isinstance(node, dict):
        for key, value in node.items():
            if key == "option" and isinstance(value, str):
                out.add(value)
            collect_options(value, out)
    elif isinstance(node, list):
        for item in node:
            collect_options(item, out)


def main() -> int:
    if not MAIN_FILE.exists() or not CONF_FILE.exists():
        return err(f"missing playbook sources under {PLAYBOOK_DIR}")

    with MAIN_FILE.open(encoding="utf-8") as handle:
        documents = [doc for doc in yaml.load_all(handle, Loader=AmeLoader) if doc]

    actions = sum(len(doc.get("actions", [])) for doc in documents if isinstance(doc, dict))
    print(f"main.yml parsed: {len(documents)} document(s), {actions} actions")

    declared = declared_options()
    used: set[str] = set()
    for doc in documents:
        collect_options(doc, used)

    problems = []
    unknown = sorted(used - declared)
    unused = sorted(declared - used - INTENTIONAL_NOOPS)
    if unknown:
        problems.append("actions reference undeclared options: " + ", ".join(unknown))
    if unused:
        problems.append("declared options never used by any action: " + ", ".join(unused))

    if problems:
        for problem in problems:
            print(f"ERROR: {problem}", file=sys.stderr)
        return 1

    print(f"OK: {len(declared)} options declared, every one referenced by an action")
    return 0


def err(message: str) -> int:
    print(f"ERROR: {message}", file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
