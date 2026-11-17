#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Type-check complete Swift examples in the DocC guides."""
from pathlib import Path
import re
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parent.parent
CATALOG = ROOT / "Sources/KaTeX/KaTeX.docc"
GUIDES = ("GettingStarted", "DisplayingMath", "RenderingAndExport", "ErrorsAndCaching")


def main():
    if len(sys.argv) != 2:
        raise SystemExit("usage: check-docc-examples.py <swift-module-directory>")
    with tempfile.TemporaryDirectory(prefix="swift-katex-examples-") as directory:
        for guide in GUIDES:
            text = (CATALOG / f"{guide}.md").read_text(encoding="utf-8")
            examples = re.findall(r"```swift\n(.*?)\n```", text, re.DOTALL)
            complete = [example for example in examples if "import KaTeX" in example]
            if not complete:
                raise SystemExit(f"No complete KaTeX example in {guide}.md")
            for index, example in enumerate(complete):
                source = Path(directory) / f"{guide}-{index}.swift"
                source.write_text(example + "\n", encoding="utf-8")
                subprocess.run(["xcrun", "swiftc", "-typecheck", "-module-cache-path", directory,
                                "-I", sys.argv[1], str(source)], check=True)
            print(f"Type-checked {guide}.md ({len(complete)} examples)", flush=True)


if __name__ == "__main__":
    main()
