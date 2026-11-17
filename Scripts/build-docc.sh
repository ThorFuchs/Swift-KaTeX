#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
# Build and validate public documentation without external dependencies.
# Usage: Scripts/build-docc.sh [scratch-directory] [output-archive]
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
scratch=${1:-"$root/.build/docc-build"}
output=${2:-"$root/.build/KaTeX.doccarchive"}
mkdir -p "$scratch" "$(dirname -- "$output")"
scratch=$(CDPATH= cd -- "$scratch" && pwd)
output="$(CDPATH= cd -- "$(dirname -- "$output")" && pwd)/$(basename -- "$output")"
cd "$root"
swift package --scratch-path "$scratch" dump-symbol-graph --skip-synthesized-members
symbol_dir="$scratch/out/symbolgraph"
python3 Scripts/check-symbol-documentation.py "$symbol_dir"
module_dir=$(swift build --scratch-path "$scratch" --show-bin-path)
python3 Scripts/check-docc-examples.py "$module_dir"
xcrun docc convert Sources/KaTeX/KaTeX.docc --additional-symbol-graph-dir "$symbol_dir" \
  --fallback-display-name KaTeX --fallback-bundle-identifier io.github.thorfuchs.swift-katex \
  --fallback-bundle-version 1.0.0 --output-path "$output" --warnings-as-errors \
  --experimental-documentation-coverage --coverage-summary-level detailed
printf 'Documentation archive: %s\n' "$output"
