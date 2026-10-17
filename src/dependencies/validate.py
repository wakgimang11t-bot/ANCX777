#!/usr/bin/env python3
"""Validate the ANCX777 playbook sources.

Checks performed:
  * Configuration/main.yml parses, with AME's !action tags treated as plain data
  * every ``option:`` referenced by an action is declared in playbook.conf
  * every declared option is used by at least one action
  * every radio page's DefaultOption names one of that page's own options

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

# Option elements carry their identifier in a <Name> child. The playbook root also
# has a <Name>, but that one is the playbook name, not an option, so options have
# to be collected by their own element tag rather than by <Name> alone.
OPTION_TAGS = frozenset({"Option", "RadioOption", "CheckboxOption"})
PAGE_TAGS = frozenset({"RadioPage", "CheckboxPage"})

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


def option_name(element: ET.Element) -> str | None:
    """The <Name> of an option element, or None when it is missing or blank."""
    child = element.find("Name")
    if child is None or not child.text:
        return None
    return child.text.strip() or None


def parse_conf() -> ET.Element:
    return ET.parse(CONF_FILE).getroot()


def declared_options(root: ET.Element) -> tuple[set[str], list[str]]:
    """Option names declared in playbook.conf, plus any malformed option elements."""
    names: set[str] = set()
    malformed: list[str] = []
    for element in root.iter():
        if element.tag not in OPTION_TAGS:
            continue
        name = option_name(element)
        if name is None:
            malformed.append(f"<{element.tag}> has no <Name>")
        else:
            names.add(name)
    return names, malformed


def default_option_mismatches(root: ET.Element) -> list[str]:
    """Radio pages whose DefaultOption is not one of the options on that page."""
    problems: list[str] = []
    for page in root.iter():
        if page.tag not in PAGE_TAGS:
            continue
        default = page.get("DefaultOption")
        if not default:
            continue
        names = {option_name(o) for o in page.iter() if o.tag in OPTION_TAGS}
        if default not in names:
            problems.append(
                f"<{page.tag}> DefaultOption '{default}' is not one of its own options"
            )
    return problems


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

    root = parse_conf()
    declared, malformed = declared_options(root)
    used: set[str] = set()
    for doc in documents:
        collect_options(doc, used)

    problems = list(malformed)
    problems.extend(default_option_mismatches(root))
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
