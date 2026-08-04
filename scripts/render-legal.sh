#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$ROOT_DIR/scripts/.generate_legal.runtime.py"
trap 'rm -f "$TMP"' EXIT
cat "$ROOT_DIR"/scripts/legal-parts/generator.part-* > "$TMP"
python3 "$TMP"
node "$ROOT_DIR/scripts/postprocess-legal.js"
