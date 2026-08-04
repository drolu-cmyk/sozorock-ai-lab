#!/usr/bin/env bash
set -euo pipefail

ROLE_NAME="${1:-}"
ACCOUNT_ID="${AWS_ACCOUNT_ID:-791860731989}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
POLICY_FILE="$ROOT_DIR/infra/iam/github-actions-oidc-trust-policy.json"
RENDERED_POLICY="$(mktemp)"
trap 'rm -f "$RENDERED_POLICY"' EXIT

if [[ -z "$ROLE_NAME" ]]; then
  echo "Usage: $0 <iam-role-name>" >&2
  exit 1
fi

aws sts get-caller-identity >/dev/null

OIDC_PROVIDER_ARN="arn:aws:iam::${ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"
if ! aws iam get-open-id-connect-provider --open-id-connect-provider-arn "$OIDC_PROVIDER_ARN" >/dev/null 2>&1; then
  aws iam create-open-id-connect-provider \
    --url https://token.actions.githubusercontent.com \
    --client-id-list sts.amazonaws.com \
    --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 >/dev/null
fi

# Keep the checked-in policy readable while allowing the operator to target
# the AWS account that owns the deployment role.
sed "s/791860731989/${ACCOUNT_ID}/g" "$POLICY_FILE" > "$RENDERED_POLICY"

aws iam update-assume-role-policy \
  --role-name "$ROLE_NAME" \
  --policy-document "file://$RENDERED_POLICY"

printf 'Updated trust policy for role %s in account %s.\n' "$ROLE_NAME" "$ACCOUNT_ID"
printf 'Re-run the GitHub Actions deployment after this command completes.\n'
