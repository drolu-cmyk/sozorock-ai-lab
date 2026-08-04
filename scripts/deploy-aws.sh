#!/usr/bin/env bash
set -euo pipefail
export AWS_PAGER=""

STACK_NAME="${STACK_NAME:-sozorock-ai-lab}"
AWS_REGION="${AWS_REGION:-us-east-1}"
SITE_BUCKET_NAME="${SITE_BUCKET_NAME:?Set SITE_BUCKET_NAME}"
DOMAIN_NAME="${DOMAIN_NAME:-ai-lab.sozorockfoundation.org}"
CERTIFICATE_ARN="${CERTIFICATE_ARN:-}"
HOSTED_ZONE_ID="${HOSTED_ZONE_ID:-}"
EXISTING_RESPONSE_HEADERS_POLICY_ID="${EXISTING_RESPONSE_HEADERS_POLICY_ID:-}"
SENDER_EMAIL="${SENDER_EMAIL:-contact@sozorockfoundation.org}"
INTERNAL_NOTIFICATION_EMAIL="${INTERNAL_NOTIFICATION_EMAIL:-contact@sozorockfoundation.org}"
FULL_APPLICATION_URL="${FULL_APPLICATION_URL:-}"
ALLOWED_ORIGIN="${ALLOWED_ORIGIN:-https://ai-lab.sozorockfoundation.org}"
APPLICATION_RATE_LIMIT="${APPLICATION_RATE_LIMIT:-5}"
APPLICATION_BURST_LIMIT="${APPLICATION_BURST_LIMIT:-10}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE="$(mktemp)"
trap 'rm -f "$TEMPLATE"' EXIT

cd "$ROOT_DIR"

stack_exists=false
if aws cloudformation describe-stacks --region "$AWS_REGION" --stack-name "$STACK_NAME" >/dev/null 2>&1; then
  stack_exists=true
fi

get_parameter() {
  aws cloudformation describe-stacks \
    --region "$AWS_REGION" \
    --stack-name "$STACK_NAME" \
    --query "Stacks[0].Parameters[?ParameterKey=='$1'].ParameterValue | [0]" \
    --output text
}

not_none() {
  if [[ -n "$1" && "$1" != "None" ]]; then
    printf '%s' "$1"
  fi
  return 0
}

print_failed_events() {
  echo "Recent failed CloudFormation events:" >&2
  aws cloudformation describe-stack-events \
    --region "$AWS_REGION" \
    --stack-name "$STACK_NAME" \
    --query "StackEvents[?contains(ResourceStatus, 'FAILED')].[Timestamp,LogicalResourceId,ResourceType,ResourceStatus,ResourceStatusReason]" \
    --output table >&2 || true
}

if [[ "$stack_exists" == true ]]; then
  [[ -n "$CERTIFICATE_ARN" ]] || CERTIFICATE_ARN="$(not_none "$(get_parameter CertificateArn)")"
  [[ -n "$HOSTED_ZONE_ID" ]] || HOSTED_ZONE_ID="$(not_none "$(get_parameter HostedZoneId)")"
  [[ -n "$FULL_APPLICATION_URL" ]] || FULL_APPLICATION_URL="$(not_none "$(get_parameter FullApplicationUrl)")"
  if [[ -z "$EXISTING_RESPONSE_HEADERS_POLICY_ID" ]]; then
    EXISTING_RESPONSE_HEADERS_POLICY_ID="$(not_none "$(get_parameter ExistingResponseHeadersPolicyId)")"
  fi
  if [[ -z "$EXISTING_RESPONSE_HEADERS_POLICY_ID" ]]; then
    EXISTING_RESPONSE_HEADERS_POLICY_ID="$(aws cloudformation describe-stack-resource \
      --region "$AWS_REGION" \
      --stack-name "$STACK_NAME" \
      --logical-resource-id SecurityHeadersPolicy \
      --query 'StackResourceDetail.PhysicalResourceId' \
      --output text 2>/dev/null || true)"
    EXISTING_RESPONSE_HEADERS_POLICY_ID="$(not_none "$EXISTING_RESPONSE_HEADERS_POLICY_ID")"
  fi
fi

if [[ -n "$DOMAIN_NAME" && -z "$CERTIFICATE_ARN" ]]; then
  echo "A certificate ARN is required for the custom domain." >&2
  exit 1
fi

ensure_log_group() {
  local log_group_name="$1"
  local existing
  existing="$(aws logs describe-log-groups \
    --region "$AWS_REGION" \
    --log-group-name-prefix "$log_group_name" \
    --query "logGroups[?logGroupName=='$log_group_name'].logGroupName | [0]" \
    --output text)"
  if [[ "$existing" == "None" || -z "$existing" ]]; then
    aws logs create-log-group \
      --region "$AWS_REGION" \
      --log-group-name "$log_group_name"
  fi
  aws logs put-retention-policy \
    --region "$AWS_REGION" \
    --log-group-name "$log_group_name" \
    --retention-in-days 30
}

ensure_log_group "/aws/lambda/${STACK_NAME}-applications"
ensure_log_group "/aws/apigateway/${STACK_NAME}-applications"

bash scripts/render-cloudformation.sh "$TEMPLATE" >/dev/null
npm test
aws cloudformation validate-template --region "$AWS_REGION" --template-body "file://$TEMPLATE" >/dev/null

if ! aws cloudformation deploy \
  --region "$AWS_REGION" \
  --stack-name "$STACK_NAME" \
  --template-file "$TEMPLATE" \
  --capabilities CAPABILITY_NAMED_IAM \
  --no-fail-on-empty-changeset \
  --parameter-overrides \
    SiteBucketName="$SITE_BUCKET_NAME" \
    DomainName="$DOMAIN_NAME" \
    CertificateArn="$CERTIFICATE_ARN" \
    HostedZoneId="$HOSTED_ZONE_ID" \
    ExistingResponseHeadersPolicyId="$EXISTING_RESPONSE_HEADERS_POLICY_ID" \
    SenderEmail="$SENDER_EMAIL" \
    InternalNotificationEmail="$INTERNAL_NOTIFICATION_EMAIL" \
    FullApplicationUrl="$FULL_APPLICATION_URL" \
    AllowedOrigin="$ALLOWED_ORIGIN" \
    ApplicationRateLimit="$APPLICATION_RATE_LIMIT" \
    ApplicationBurstLimit="$APPLICATION_BURST_LIMIT"; then
  print_failed_events
  exit 1
fi

get_output() {
  aws cloudformation describe-stacks \
    --region "$AWS_REGION" \
    --stack-name "$STACK_NAME" \
    --query "Stacks[0].Outputs[?OutputKey=='$1'].OutputValue | [0]" \
    --output text
}

DISTRIBUTION_ID="$(get_output DistributionId)"
DISTRIBUTION_DOMAIN="$(get_output DistributionDomainName)"
BUCKET_NAME="$(get_output BucketName)"

if [[ -z "$DISTRIBUTION_ID" || "$DISTRIBUTION_ID" == "None" ]]; then
  echo "CloudFormation did not return a CloudFront distribution ID." >&2
  exit 1
fi

if [[ -z "$BUCKET_NAME" || "$BUCKET_NAME" == "None" ]]; then
  echo "CloudFormation did not return an S3 bucket name." >&2
  exit 1
fi

aws s3 sync dist/assets/ "s3://$BUCKET_NAME/assets/" \
  --delete \
  --cache-control "public,max-age=31536000,immutable"

aws s3 sync dist/ "s3://$BUCKET_NAME/" \
  --delete \
  --exclude "assets/*" \
  --cache-control "no-cache,no-store,must-revalidate"

INVALIDATION_ID="$(aws cloudfront create-invalidation \
  --distribution-id "$DISTRIBUTION_ID" \
  --paths '/*' \
  --query 'Invalidation.Id' \
  --output text)"

aws cloudfront wait invalidation-completed \
  --distribution-id "$DISTRIBUTION_ID" \
  --id "$INVALIDATION_ID"

printf 'Deployment complete\n'
printf '  stack: %s\n' "$STACK_NAME"
printf '  bucket: %s\n' "$BUCKET_NAME"
printf '  distribution: %s\n' "$DISTRIBUTION_ID"
printf '  distribution domain: %s\n' "$DISTRIBUTION_DOMAIN"
printf '  public URL: https://%s\n' "$DOMAIN_NAME"
