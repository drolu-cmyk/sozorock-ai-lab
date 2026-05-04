#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/drolu-cmyk/sozorock-ai-lab.git"
BRANCH="main"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git init
fi

git branch -M "$BRANCH"
git remote remove origin >/dev/null 2>&1 || true
git remote add origin "$REPO_URL"
git add .
git commit -m "Build SozoRock AI Lab static site" || true
git push -u origin "$BRANCH"
