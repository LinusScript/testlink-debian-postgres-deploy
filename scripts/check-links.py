#!/usr/bin/env python3
"""Prueft alle internen Markdown-Links (*.md) in diesem Repo auf Gueltigkeit.

Nutzung: python3 scripts/check-links.py
Exit-Code 0 = alle Links intakt, 1 = mindestens ein kaputter Link gefunden.

Prueft absichtlich NUR interne .md-Links (schnell, deterministisch, keine
Netzwerkabhaengigkeit) - keine externen http(s)-Links, um die CI nicht von
Erreichbarkeit/Rate-Limits fremder Server abhaengig zu machen.
"""
import os
import re
import sys

LINK_PATTERN = re.compile(r'\]\(([^)]+\.md)(#[^)]*)?\)')


def find_markdown_files(root):
    for dirpath, _dirnames, filenames in os.walk(root):
        for fn in filenames:
            if fn.endswith(".md"):
                yield os.path.join(dirpath, fn)


def check_repo(repo_root):
    broken = []
    checked = 0
    for path in find_markdown_files(repo_root):
        with open(path, encoding="utf-8") as f:
            content = f.read()
        for match in LINK_PATTERN.finditer(content):
            link = match.group(1)
            if link.startswith("http"):
                continue
            checked += 1
            target = os.path.normpath(os.path.join(os.path.dirname(path), link))
            if not os.path.isfile(target):
                broken.append((path, link, target))
    return checked, broken


def main():
    repo_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    checked, broken = check_repo(repo_root)

    if broken:
        print(f"FEHLER: {len(broken)} von {checked} internen Links kaputt:\n")
        for source, link, target in broken:
            rel_source = os.path.relpath(source, repo_root)
            print(f"  {rel_source} -> '{link}' (aufgeloest: {target})")
        return 1

    print(f"OK: alle {checked} internen Markdown-Links intakt.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
