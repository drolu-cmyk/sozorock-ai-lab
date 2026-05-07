#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

rm -rf dist dist-ai-lab-prefix
mkdir -p dist dist-ai-lab-prefix/ai-lab
cp -R site/. dist/
cp -R site/. dist-ai-lab-prefix/ai-lab/

mkdir -p dist/assets/img dist-ai-lab-prefix/ai-lab/assets/img
cp design/reference-collages/sozorock-ai-lab-reference-grid-01.png dist/assets/img/social-preview.png
cp design/reference-collages/sozorock-ai-lab-reference-grid-01.png dist-ai-lab-prefix/ai-lab/assets/img/social-preview.png

cp site/index.html dist/404.html
cp site/index.html dist-ai-lab-prefix/ai-lab/404.html

echo "Built dist outputs."
