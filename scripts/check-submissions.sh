#!/usr/bin/env bash
set -euo pipefail

export AWS_PAGER=""

MODE="${MODE:-list}"
STACK_NAME="${STACK_NAME:-sozorock-ai-lab}"
AWS_REGION="${AWS_REGION:-us-east-1}"
AI_LAB_DOMAIN="${AI_LAB_DOMAIN:-ai-lab.sozorockfoundation.org}"
RECENT_LIMIT="${RECENT_LIMIT:-20}"
SHOW_FULL_SUBMISSIONS="${SHOW_FULL_SUBMISSIONS:-0}"
SMOKE_EMAIL="${SMOKE_EMAIL:-}"
SMOKE_ENDPOINT="${SMOKE_ENDPOINT:-https://${AI_LAB_DOMAIN}/api/applications/start}"

usage() {
  cat <<'USAGE'
Usage: scripts/check-submissions.sh [--mode list|smoke-test] [--stack-name NAME] [--region REGION]

Environment:
  STACK_NAME              CloudFormation stack name. Default: sozorock-ai-lab
  AWS_REGION              AWS region. Default: us-east-1
  AI_LAB_DOMAIN           Live AI Lab domain. Default: ai-lab.sozorockfoundation.org
  SMOKE_ENDPOINT          Full POST endpoint for smoke tests. Default: https://$AI_LAB_DOMAIN/api/applications/start
  RECENT_LIMIT            Number of recent scan items to print. Default: 20
  SHOW_FULL_SUBMISSIONS   Set to 1 to print full applicant values.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)
      MODE="${2:?Missing mode}"
      shift 2
      ;;
    --stack-name)
      STACK_NAME="${2:?Missing stack name}"
      shift 2
      ;;
    --region)
      AWS_REGION="${2:?Missing region}"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

need() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 127
  fi
}

need aws
need python3

resolve_table_name() {
  local output_name resource_name
  output_name="$(aws cloudformation describe-stacks \
    --region "$AWS_REGION" \
    --stack-name "$STACK_NAME" \
    --query "Stacks[0].Outputs[?OutputKey=='ApplicationsTableName'].OutputValue | [0]" \
    --output text 2>/dev/null | sed 's/^None$//')"
  if [[ -n "$output_name" ]]; then
    echo "$output_name"
    return 0
  fi

  resource_name="$(aws cloudformation describe-stack-resources \
    --region "$AWS_REGION" \
    --stack-name "$STACK_NAME" \
    --logical-resource-id ApplicationsTable \
    --query "StackResources[0].PhysicalResourceId" \
    --output text 2>/dev/null | sed 's/^None$//')"
  if [[ -n "$resource_name" ]]; then
    echo "$resource_name"
    return 0
  fi

  echo "Could not resolve ApplicationsTable from stack '$STACK_NAME' in '$AWS_REGION'." >&2
  echo "Check STACK_NAME, AWS_REGION, and cloudformation:DescribeStacks/DescribeStackResources permissions." >&2
  return 1
}

print_submissions() {
  local table_name="$1" raw
  raw="$(aws dynamodb scan \
    --region "$AWS_REGION" \
    --table-name "$table_name" \
    --limit "$RECENT_LIMIT" \
    --output json)"

  SHOW_FULL_SUBMISSIONS="$SHOW_FULL_SUBMISSIONS" python3 - "$raw" <<'PY'
import json
import os
import sys

payload = json.loads(sys.argv[1])
show_full = os.environ.get("SHOW_FULL_SUBMISSIONS") == "1"

def attr(item, key, kind="S"):
    value = item.get(key, {})
    if kind == "BOOL":
        return value.get("BOOL")
    if kind == "N":
        return value.get("N")
    return value.get(kind, "")

def redact_email(email):
    if not email or "@" not in email:
        return "[redacted]"
    local, domain = email.split("@", 1)
    return f"{local[:1]}***@{domain}"

items = sorted(payload.get("Items", []), key=lambda item: attr(item, "submittedAt"), reverse=True)
if not items:
    print("No submissions found.")
    sys.exit(0)

for item in items:
    row = {
        "submittedAt": attr(item, "submittedAt"),
        "id": attr(item, "id"),
        "status": attr(item, "status"),
        "source": attr(item, "source"),
        "cohort": attr(item, "cohort"),
        "consent": attr(item, "consent", "BOOL"),
        "email": attr(item, "email") if show_full else redact_email(attr(item, "email")),
    }
    if show_full:
        row.update({
            "firstName": attr(item, "firstName"),
            "lastName": attr(item, "lastName"),
            "build": attr(item, "build"),
        })
    print(json.dumps(row, ensure_ascii=True))
PY
}

post_smoke_submission() {
  local email body status response_file
  email="${SMOKE_EMAIL:-ai-lab-smoke-$(date +%Y%m%d%H%M%S)@example.invalid}"
  body=$(cat <<JSON
{"firstName":"Smoke","lastName":"Test","email":"${email}","build":"Automated smoke test for AI Lab submission wiring.","consent":true,"website":"","source":"sozorock-ai-lab-website","cohort":"Cohort 02"}
JSON
)
  response_file="$(mktemp)"
  status="$(curl -sS -o "$response_file" -w "%{http_code}" \
    -X POST "$SMOKE_ENDPOINT" \
    -H "content-type: application/json" \
    --data "$body")"

  if [[ "$status" -lt 200 || "$status" -ge 300 ]]; then
    echo "Smoke submission failed with HTTP $status at $SMOKE_ENDPOINT" >&2
    sed 's/./*/g' "$response_file" >&2
    rm -f "$response_file"
    return 1
  fi
  rm -f "$response_file"
  echo "Smoke submission accepted by $SMOKE_ENDPOINT"
  echo "$email"
}

wait_for_smoke_record() {
  local table_name="$1" email="$2" attempt count
  for attempt in {1..12}; do
    count="$(aws dynamodb scan \
      --region "$AWS_REGION" \
      --table-name "$table_name" \
      --filter-expression "email = :email" \
      --expression-attribute-values "{\":email\":{\"S\":\"${email}\"}}" \
      --select COUNT \
      --output text \
      --query "Count")"
    if [[ "$count" != "0" ]]; then
      echo "Smoke submission found in DynamoDB table $table_name."
      return 0
    fi
    sleep 5
  done

  echo "Smoke submission was accepted but not found in DynamoDB after waiting." >&2
  echo "Check Lambda logs, API Gateway route integration, and DynamoDB PutItem permissions." >&2
  return 1
}

case "$MODE" in
  list)
    TABLE_NAME="$(resolve_table_name)"
    echo "Recent submissions from $TABLE_NAME in $AWS_REGION. PII redacted by default."
    print_submissions "$TABLE_NAME"
    ;;
  smoke-test)
    TABLE_NAME="$(resolve_table_name)"
    SMOKE_EMAIL="$(post_smoke_submission | tee /dev/stderr | tail -n 1)"
    wait_for_smoke_record "$TABLE_NAME" "$SMOKE_EMAIL"
    ;;
  *)
    echo "Unsupported MODE: $MODE" >&2
    usage >&2
    exit 2
    ;;
esac
