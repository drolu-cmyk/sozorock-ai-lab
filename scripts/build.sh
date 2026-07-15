#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
bash scripts/render-legal.sh
rm -rf dist
mkdir -p dist
cp -R site/. dist/
find dist -type f -name '.DS_Store' -delete
if [[ -f design/reference-collages/sozorock-ai-lab-reference-grid-01.png ]]; then
  mkdir -p dist/assets/img
  cp design/reference-collages/sozorock-ai-lab-reference-grid-01.png dist/assets/img/social-preview.png
fi
printf 'Built production output in dist/.\n'
