#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT="${1:-$ROOT_DIR/infra/cloudformation/cloudfront-s3-private.generated.yml}"
cat "$ROOT_DIR"/infra/cloudformation/parts/template.part-* > "$OUTPUT"
printf '%s\n' "$OUTPUT"
