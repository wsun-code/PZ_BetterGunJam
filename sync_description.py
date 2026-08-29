#!/usr/bin/env python3
"""
Sync a Project Zomboid workshop description file into a workshop.txt.

Usage:
    python sync_description.py <DESCRIPTION> <workshop.txt>
    python sync_description.py --no-id <DESCRIPTION> <workshop.txt>

The DESCRIPTION file is the metadata source. Everything above the first
"Workshop ID:" / "Mod ID:" trailer line becomes the description; each line
(blank lines included) is written as its own "description=" key, which the
game's workshop uploader rejoins with newlines:

    description=<line 1>
    description=<line 2>
    ...

Trailer mapping:
    "Workshop ID: <n>"  ->  id=<n>     (replaces the existing id= key)
    "Mod ID: <id>"      ->  ignored    (the game reads the mod id from the
                                        mod's mod.info, not this file)

By default the id= key is synced from "Workshop ID:". Pass --no-id to keep
the existing id= in workshop.txt (e.g. when publishing to a dev item whose
DESCRIPTION carries the production item's boilerplate id).

All other keys in workshop.txt (version, title, tags, visibility) are
preserved in place. If workshop.txt lacks an id= or description= key, the
synced values are appended at the end. If DESCRIPTION has no "Workshop ID:"
trailer (or --no-id is given), the existing id= is kept. A missing
workshop.txt is created with version=1, the synced id and description.
"""
import re
import sys
from pathlib import Path

ID_RE = re.compile(r"^\s*Workshop ID:\s*(\S+)\s*$")
TRAILER_RE = re.compile(r"^\s*(?:Workshop ID|Mod ID):")


def main() -> int:
    args = sys.argv[1:]
    sync_id = True
    if args and args[0] == "--no-id":
        sync_id = False
        args = args[1:]
    if args and args[0] in ("-h", "--help"):
        print(__doc__)
        return 0
    if len(args) != 2:
        print(f"usage: python {sys.argv[0]} [--no-id] <DESCRIPTION> "
              "<workshop.txt>", file=sys.stderr)
        return 2

    desc_path, ws_path = (Path(arg) for arg in args)

    lines = desc_path.read_text(encoding="utf-8").splitlines()
    trailer = next(
        (i for i, line in enumerate(lines) if TRAILER_RE.match(line)),
        len(lines),
    )
    content = lines[:trailer]
    # A blank separator line before the metadata trailer is formatting,
    # not description content — drop trailing empty lines only.
    while content and content[-1] == "":
        content.pop()

    workshop_id = None
    if sync_id:
        for line in lines[trailer:]:
            m = ID_RE.match(line)
            if m:
                workshop_id = m.group(1)
        if workshop_id is None:
            print("warning: no 'Workshop ID:' trailer in DESCRIPTION; "
                  "existing id kept", file=sys.stderr)

    out: list[str] = []
    wrote_id = False
    wrote_desc = False
    try:
        ws_lines = ws_path.read_text(encoding="utf-8").splitlines()
    except FileNotFoundError:
        ws_lines = []
        print(f"note: {ws_path} does not exist; creating it", file=sys.stderr)
        out.append("version=1")
    for line in ws_lines:
        if line.startswith("description="):
            if not wrote_desc:
                out.extend(f"description={c}" for c in content)
                wrote_desc = True
            continue
        if line.startswith("id="):
            out.append(line if workshop_id is None else f"id={workshop_id}")
            wrote_id = True
            continue
        out.append(line)

    if not wrote_id and workshop_id is not None:
        out.append(f"id={workshop_id}")
    if not wrote_desc:
        out.extend(f"description={c}" for c in content)

    ws_path.write_text("\n".join(out) + "\n", encoding="utf-8")

    print(f"id={'unchanged' if workshop_id is None else workshop_id}")
    print(f"description: {len(content)} line(s) -> {ws_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
