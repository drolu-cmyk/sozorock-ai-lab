#!/usr/bin/env bash
set -euo pipefail

ROLE_NAME="${1:-GitHubActionsSozorockAiLabDeployRole}"
SITE_BUCKET_NAME="${2:-${SITE_BUCKET_NAME:-}}"
ACCOUNT_ID="${AWS_ACCOUNT_ID:-791860731989}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TRUST_POLICY_TEMPLATE="$ROOT_DIR/infra/iam/github-actions-oidc-trust-policy.json"
DEPLOY_POLICY_TEMPLATE="$ROOT_DIR/infra/iam/github-actions-deploy-policy.json"
TRUST_POLICY="$(mktemp)"
DEPLOY_POLICY="$(mktemp)"
trap 'rm -f "$TRUST_POLICY" "$DEPLOY_POLICY"' EXIT

if [[ -z "$SITE_BUCKET_NAME" ]]; then
  echo "Usage: $0 [iam-role-name] <site-bucket-name>" >&2
  echo "Set SITE_BUCKET_NAME instead of the second argument if preferred." >&2
  exit 1
fi

if [[ ! "$ACCOUNT_ID" =~ ^[0-9]{12}$ ]]; then
  echo "AWS_ACCOUNT_ID must be a 12-digit account ID." >&2
  exit 1
fi

CALLER_ACCOUNT="$(aws sts get-caller-identity --query Account --output text)"
if [[ "$CALLER_ACCOUNT" != "$ACCOUNT_ID" ]]; then
  echo "The active AWS identity belongs to account $CALLER_ACCOUNT, expected $ACCOUNT_ID." >&2
  exit 1
fi

# The checked-in trust policy is pinned to the known AI Lab account. Render a
# temporary account-specific copy so the bootstrap cannot target another
# account while retaining the repository policy as the reviewable source.
sed "s/791860731989/$ACCOUNT_ID/g" "$TRUST_POLICY_TEMPLATE" > "$TRUST_POLICY"
sed \
  -e "s/YOUR_BUCKET_NAME/$SITE_BUCKET_NAME/g" \
  -e "s/ACCOUNT_ID/$ACCOUNT_ID/g" \
  "$DEPLOY_POLICY_TEMPLATE" > "$DEPLOY_POLICY"

OIDC_PROVIDER_ARN="arn:aws:iam::${ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"
if ! aws iam get-open-id-connect-provider \
  --open-id-connect-provider-arn "$OIDC_PROVIDER_ARN" >/dev/null 2>&1; then
  aws iam create-open-id-connect-provider \
    --url https://token.actions.githubusercontent.com \
    --client-id-list sts.amazonaws.com \
    --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 >/dev/null
  echo "Created GitHub Actions OIDC provider."
fi

if ! aws iam get-role --role-name "$ROLE_NAME" >/dev/null 2>&1; then
  aws iam create-role \
    --role-name "$ROLE_NAME" \
    --description "Dedicated SozoRock AI Lab GitHub Actions deployment role" \
    --assume-role-policy-document "file://$TRUST_POLICY" >/dev/null
  echo "Created IAM role $ROLE_NAME."
fi

aws iam update-assume-role-policy \
  --role-name "$ROLE_NAME" \
  --policy-document "file://$TRUST_POLICY"

aws iam put-role-policy \
  --role-name "$ROLE_NAME" \
  --policy-name SozoRockAiLabDeployment \
  --policy-document "file://$DEPLOY_POLICY"

ROLE_ARN="$(aws iam get-role --role-name "$ROLE_NAME" --query Role.Arn --output text)"
printf 'Configured dedicated AI Lab deployment role.\n'
printf '  account: %s\n' "$ACCOUNT_ID"
printf '  role: %s\n' "$ROLE_ARN"
printf '  bucket policy target: %s\n' "$SITE_BUCKET_NAME"
printf 'Set GitHub secret AWS_ROLE_TO_ASSUME to the role ARN above, then rerun the AI Lab workflow.\n'
