#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
bash scripts/render-legal.sh
rm -rf dist
mkdir -p dist
cp -R site/. dist/
find dist -type f -name '.DS_Store' -delete
printf 'Built production output in dist/.\n'
