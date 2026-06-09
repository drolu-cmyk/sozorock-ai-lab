#!/usr/bin/env bash
set -euo pipefail

ADMIN_API_SECRET="${ADMIN_API_SECRET:-}"
FULL_APPLICATION_URL="${FULL_APPLICATION_URL:-}"
AI_LAB_DOMAIN="${AI_LAB_DOMAIN:-ai-lab.sozorockfoundation.org}"
SELECTED_ENDPOINT="${SELECTED_ENDPOINT:-https://${AI_LAB_DOMAIN}/api/applications/selected}"

usage() {
  cat <<'USAGE'
Usage: scripts/send-selected-application.sh recipient@example.com "First Name" [application-url]

Environment:
  ADMIN_API_SECRET       Required shared secret for POST /api/applications/selected.
  FULL_APPLICATION_URL   Default full application URL when no URL argument is passed.
  AI_LAB_DOMAIN          AI Lab domain. Default: ai-lab.sozorockfoundation.org.
  SELECTED_ENDPOINT      Full protected endpoint. Default: https://$AI_LAB_DOMAIN/api/applications/selected.
USAGE
}

if [[ $# -lt 2 || "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit $([[ $# -lt 2 ]] && echo 2 || echo 0)
fi

if [[ -z "$ADMIN_API_SECRET" ]]; then
  echo "ADMIN_API_SECRET is required." >&2
  exit 2
fi

EMAIL="$1"
FIRST_NAME="$2"
APPLICATION_URL="${3:-$FULL_APPLICATION_URL}"

if [[ -z "$APPLICATION_URL" ]]; then
  echo "Provide an application URL argument or set FULL_APPLICATION_URL." >&2
  exit 2
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "Missing required command: curl" >&2
  exit 127
fi
if ! command -v python3 >/dev/null 2>&1; then
  echo "Missing required command: python3" >&2
  exit 127
fi

PAYLOAD="$(python3 - "$EMAIL" "$FIRST_NAME" "$APPLICATION_URL" <<'PY'
import json
import sys

email, first_name, application_url = sys.argv[1:4]
print(json.dumps({
    "email": email,
    "firstName": first_name,
    "applicationUrl": application_url,
}))
PY
)"

response_file="$(mktemp)"
status="$(curl -sS -o "$response_file" -w "%{http_code}" \
  -X POST "$SELECTED_ENDPOINT" \
  -H "content-type: application/json" \
  -H "x-admin-secret: ${ADMIN_API_SECRET}" \
  --data "$PAYLOAD")"

if [[ "$status" -lt 200 || "$status" -ge 300 ]]; then
  echo "Selected-applicant send failed with HTTP $status." >&2
  cat "$response_file" >&2
  rm -f "$response_file"
  exit 1
fi

if ! python3 - "$response_file" <<'PY'
import json
import sys

with open(sys.argv[1], "r", encoding="utf-8") as handle:
    payload = json.load(handle)
if payload.get("ok") is not True:
    raise SystemExit(1)
PY
then
  echo "Selected-applicant endpoint returned an unexpected response." >&2
  cat "$response_file" >&2
  rm -f "$response_file"
  exit 1
fi

rm -f "$response_file"
python3 - "$EMAIL" <<'PY'
import sys

email = sys.argv[1]
if "@" in email:
    local, domain = email.split("@", 1)
    email = f"{local[:1]}***@{domain}"
else:
    email = "[redacted]"
print(f"Full application email request accepted for {email}.")
PY
