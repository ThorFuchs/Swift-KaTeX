#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Require documentation on public, source-declared KaTeX symbols."""
import json
from pathlib import Path
import sys


def main():
    if len(sys.argv) != 2:
        raise SystemExit("usage: check-symbol-documentation.py <symbol-graph-directory>")
    paths = list(Path(sys.argv[1]).glob("KaTeX*.symbols.json"))
    if not paths:
        raise SystemExit("No KaTeX symbol graphs found")
    declared = {}
    for path in paths:
        symbols = json.loads(path.read_text(encoding="utf-8"))["symbols"]
        if isinstance(symbols, dict):
            symbols = symbols.values()
        for symbol in symbols:
            location = symbol.get("location", {}).get("uri", "")
            if (symbol.get("accessLevel") == "public" and "/Sources/KaTeX/" in location
                    and symbol.get("kind", {}).get("identifier") != "swift.extension"):
                declared[symbol["identifier"]["precise"]] = symbol
    if not declared:
        raise SystemExit("No source-declared public symbols found")
    missing = [symbol for symbol in declared.values() if not symbol.get("docComment", {}).get("lines")]
    for symbol in missing:
        print("Undocumented public symbol:", ".".join(symbol["pathComponents"]))
    print(f"Documented public source symbols: {len(declared) - len(missing)}/{len(declared)}")
    return 1 if missing else 0


if __name__ == "__main__":
    sys.exit(main())
