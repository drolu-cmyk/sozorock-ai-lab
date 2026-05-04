#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

rm -rf dist dist-ai-lab-prefix
mkdir -p dist dist-ai-lab-prefix/ai-lab
cp -R site/. dist/
cp -R site/. dist-ai-lab-prefix/ai-lab/

# 404 page for CloudFront custom error responses.
cp site/index.html dist/404.html
cp site/index.html dist-ai-lab-prefix/ai-lab/404.html

echo "Built dist/ for root/subdomain hosting."
echo "Built dist-ai-lab-prefix/ai-lab/ for www.sozorockfoundation.org/ai-lab/ hosting."
