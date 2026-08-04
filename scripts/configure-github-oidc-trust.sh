#!/usr/bin/env bash
set -euo pipefail

ROLE_NAME="${ROLE_NAME:-GitHubActionsSozorockAiLabDeployRole}"
SITE_BUCKET_NAME="${SITE_BUCKET_NAME:-}"
STACK_NAME="${STACK_NAME:-sozorock-ai-lab}"
ACCOUNT_ID="${AWS_ACCOUNT_ID:-791860731989}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TRUST_POLICY_TEMPLATE="$ROOT_DIR/infra/iam/github-actions-oidc-trust-policy.json"
DEPLOY_POLICY_TEMPLATE="$ROOT_DIR/infra/iam/github-actions-deploy-policy.json"
TRUST_POLICY="$(mktemp)"
DEPLOY_POLICY="$(mktemp)"
trap 'rm -f "$TRUST_POLICY" "$DEPLOY_POLICY"' EXIT

usage() {
  echo "Usage: $0 [site-bucket-name]" >&2
  echo "       $0 <iam-role-name> <site-bucket-name> [stack-name]" >&2
  echo "Set SITE_BUCKET_NAME, STACK_NAME, or ROLE_NAME to use environment defaults." >&2
}

case "$#" in
  0)
    ;;
  1)
    # The documented one-argument form is always the bucket. A custom
    # role can be supplied through ROLE_NAME or the explicit two-argument form.
    SITE_BUCKET_NAME="$1"
    ;;
  2)
    ROLE_NAME="$1"
    SITE_BUCKET_NAME="$2"
    ;;
  3)
    ROLE_NAME="$1"
    SITE_BUCKET_NAME="$2"
    STACK_NAME="$3"
    ;;
  *)
    usage
    exit 1
    ;;
esac
if [[ -z "$SITE_BUCKET_NAME" ]]; then
  usage
  exit 1
fi

if [[ ! "$ACCOUNT_ID" =~ ^[0-9]{12}$ ]]; then
  echo "AWS_ACCOUNT_ID must be a 12-digit account ID." >&2
  exit 1
fi

if [[ ! "$STACK_NAME" =~ ^[a-zA-Z][a-zA-Z0-9-]*$ ]]; then
  echo "STACK_NAME must start with a letter and contain only letters, numbers, and hyphens." >&2
  exit 1
fi

CALLER_ACCOUNT="$(aws sts get-caller-identity --query Account --output text)"
if [[ "$CALLER_ACCOUNT" != "$ACCOUNT_ID" ]]; then
  echo "The active AWS identity belongs to account $CALLER_ACCOUNT, expected $ACCOUNT_ID." >&2
  exit 1
fi

# Render temporary account, bucket, and stack-specific copies while retaining
# the checked-in policy templates as the reviewable source of truth.
sed "s/791860731989/$ACCOUNT_ID/g" "$TRUST_POLICY_TEMPLATE" > "$TRUST_POLICY"
sed \
  -e "s/YOUR_BUCKET_NAME/$SITE_BUCKET_NAME/g" \
  -e "s/ACCOUNT_ID/$ACCOUNT_ID/g" \
  -e "s/STACK_NAME/$STACK_NAME/g" \
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
printf '  stack policy target: %s\n' "$STACK_NAME"
printf 'GitHub Actions uses the dedicated default role ARN automatically.\n'
printf 'Set repository variable AWS_ROLE_TO_ASSUME only when intentionally using a different role ARN.\n'
