#!/usr/bin/env bash
set -euo pipefail

export AWS_PAGER=""

STACK_NAME="${STACK_NAME:-sozorock-ai-lab}"
AWS_REGION="${AWS_REGION:-us-east-1}"
SITE_BUCKET_NAME="${SITE_BUCKET_NAME:?Set SITE_BUCKET_NAME, e.g. sozorock-ai-lab-prod-ACCOUNTID}"
DOMAIN_NAME="${DOMAIN_NAME:-}"
CERTIFICATE_ARN="${CERTIFICATE_ARN:-}"
HOSTED_ZONE_ID="${HOSTED_ZONE_ID:-}"
SENDER_EMAIL="${SENDER_EMAIL:-contact@sozorockfoundation.org}"
INTERNAL_NOTIFICATION_EMAIL="${INTERNAL_NOTIFICATION_EMAIL:-contact@sozorockfoundation.org}"
FULL_APPLICATION_URL="${FULL_APPLICATION_URL:-}"
ADMIN_API_SECRET="${ADMIN_API_SECRET:-}"
ALLOWED_ORIGIN="${ALLOWED_ORIGIN:-https://ai-lab.sozorockfoundation.org}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

stack_exists() {
  aws cloudformation describe-stacks --region "$AWS_REGION" --stack-name "$STACK_NAME" >/dev/null 2>&1
}

stack_status() {
  aws cloudformation describe-stacks --region "$AWS_REGION" --stack-name "$STACK_NAME" --query "Stacks[0].StackStatus" --output text 2>/dev/null || true
}

stack_parameter() {
  local key="$1"
  aws cloudformation describe-stacks \
    --region "$AWS_REGION" \
    --stack-name "$STACK_NAME" \
    --query "Stacks[0].Parameters[?ParameterKey=='${key}'].ParameterValue | [0]" \
    --output text 2>/dev/null | sed 's/^None$//'
}

print_failed_events() {
  echo "Latest failed CloudFormation events:" >&2
  aws cloudformation describe-stack-events \
    --region "$AWS_REGION" \
    --stack-name "$STACK_NAME" \
    --query "StackEvents[?contains(ResourceStatus, 'FAILED')].[Timestamp,LogicalResourceId,ResourceType,ResourceStatus,ResourceStatusReason]" \
    --max-items 20 \
    --output table >&2 || true
}

recover_stack_if_needed() {
  if ! stack_exists; then
    return 0
  fi

  local status
  status="$(stack_status)"
  echo "Current CloudFormation stack status: ${status:-unknown}"

  case "$status" in
    UPDATE_ROLLBACK_FAILED)
      echo "Stack is in UPDATE_ROLLBACK_FAILED. Continuing rollback before deploy..."
      aws cloudformation continue-update-rollback --region "$AWS_REGION" --stack-name "$STACK_NAME"
      aws cloudformation wait stack-update-rollback-complete --region "$AWS_REGION" --stack-name "$STACK_NAME"
      ;;
    UPDATE_ROLLBACK_IN_PROGRESS)
      echo "Stack rollback is already in progress. Waiting for rollback to complete..."
      aws cloudformation wait stack-update-rollback-complete --region "$AWS_REGION" --stack-name "$STACK_NAME"
      ;;
    UPDATE_IN_PROGRESS|UPDATE_COMPLETE_CLEANUP_IN_PROGRESS|REVIEW_IN_PROGRESS|CREATE_IN_PROGRESS|DELETE_IN_PROGRESS|ROLLBACK_IN_PROGRESS)
      echo "Stack operation is already in progress. Waiting for it to settle..."
      aws cloudformation wait stack-update-complete --region "$AWS_REGION" --stack-name "$STACK_NAME" || true
      aws cloudformation wait stack-update-rollback-complete --region "$AWS_REGION" --stack-name "$STACK_NAME" || true
      ;;
  esac

  echo "Stack status after recovery check: $(stack_status)"
}

infer_missing_parameters() {
  if stack_exists; then
    DOMAIN_NAME="${DOMAIN_NAME:-$(stack_parameter DomainName)}"
    CERTIFICATE_ARN="${CERTIFICATE_ARN:-$(stack_parameter CertificateArn)}"
    HOSTED_ZONE_ID="${HOSTED_ZONE_ID:-$(stack_parameter HostedZoneId)}"
    FULL_APPLICATION_URL="${FULL_APPLICATION_URL:-$(stack_parameter FullApplicationUrl)}"
  fi

  if [[ -n "$DOMAIN_NAME" && -z "$CERTIFICATE_ARN" ]]; then
    CERTIFICATE_ARN="$(aws acm list-certificates \
      --region us-east-1 \
      --query "CertificateSummaryList[?DomainName=='${DOMAIN_NAME}'].CertificateArn | [0]" \
      --output text 2>/dev/null | sed 's/^None$//')"
  fi

  if [[ -n "$DOMAIN_NAME" && -z "$CERTIFICATE_ARN" ]]; then
    local base_domain
    base_domain="$(echo "$DOMAIN_NAME" | awk -F. '{print $(NF-1)"."$NF}')"
    CERTIFICATE_ARN="$(aws acm list-certificates \
      --region us-east-1 \
      --query "CertificateSummaryList[?DomainName=='*.${base_domain}'].CertificateArn | [0]" \
      --output text 2>/dev/null | sed 's/^None$//')"
  fi

  if [[ -n "$DOMAIN_NAME" && -z "$HOSTED_ZONE_ID" ]]; then
    local base_domain
    base_domain="$(echo "$DOMAIN_NAME" | awk -F. '{print $(NF-1)"."$NF}')"
    HOSTED_ZONE_ID="$(aws route53 list-hosted-zones-by-name \
      --dns-name "$base_domain" \
      --query "HostedZones[?Name=='${base_domain}.'].Id | [0]" \
      --output text 2>/dev/null | sed 's#^/hostedzone/##; s/^None$//')"
  fi

  echo "Deployment parameter summary:"
  echo "  Stack: $STACK_NAME"
  echo "  Region: $AWS_REGION"
  echo "  Bucket: $SITE_BUCKET_NAME"
  echo "  Domain: ${DOMAIN_NAME:-none}"
  echo "  Certificate: $([[ -n "$CERTIFICATE_ARN" ]] && echo set || echo missing)"
  echo "  Hosted zone: $([[ -n "$HOSTED_ZONE_ID" ]] && echo set || echo missing)"
  echo "  Full application URL: $([[ -n "$FULL_APPLICATION_URL" ]] && echo set || echo missing)"
  echo "  Admin API secret: $([[ -n "$ADMIN_API_SECRET" ]] && echo set || echo missing)"
}

deploy_stack_if_safe() {
  if [[ -n "$DOMAIN_NAME" && -z "$CERTIFICATE_ARN" ]]; then
    echo "WARNING: DOMAIN_NAME is set but CERTIFICATE_ARN is missing." >&2
    echo "Skipping CloudFormation update to avoid breaking the existing CloudFront custom domain." >&2
    return 0
  fi

  if ! aws cloudformation deploy \
    --region "$AWS_REGION" \
    --stack-name "$STACK_NAME" \
    --template-file infra/cloudformation/cloudfront-s3-private.yml \
    --capabilities CAPABILITY_NAMED_IAM \
    --parameter-overrides \
      SiteBucketName="$SITE_BUCKET_NAME" \
      DomainName="$DOMAIN_NAME" \
      CertificateArn="$CERTIFICATE_ARN" \
      HostedZoneId="$HOSTED_ZONE_ID" \
      SenderEmail="$SENDER_EMAIL" \
      InternalNotificationEmail="$INTERNAL_NOTIFICATION_EMAIL" \
      FullApplicationUrl="$FULL_APPLICATION_URL" \
      AdminApiSecret="$ADMIN_API_SECRET" \
      AllowedOrigin="$ALLOWED_ORIGIN"; then
    print_failed_events
    exit 1
  fi
}

get_output() {
  local key="$1"
  aws cloudformation describe-stacks --region "$AWS_REGION" --stack-name "$STACK_NAME" --query "Stacks[0].Outputs[?OutputKey=='${key}'].OutputValue | [0]" --output text
}

bash scripts/build.sh
recover_stack_if_needed
infer_missing_parameters
deploy_stack_if_safe

DISTRIBUTION_ID="$(get_output DistributionId)"
BUCKET_NAME="$(get_output BucketName)"
DISTRIBUTION_DOMAIN="$(get_output DistributionDomainName)"

aws s3 sync dist/assets/ "s3://$BUCKET_NAME/assets/" --delete --cache-control "public,max-age=31536000,immutable"
aws s3 sync dist/images/ "s3://$BUCKET_NAME/images/" --delete --cache-control "public,max-age=31536000,immutable"
aws s3 sync dist/ "s3://$BUCKET_NAME/" --delete --exclude "assets/*" --exclude "images/*" --cache-control "no-cache,no-store,must-revalidate"

INVALIDATION_ID="$(aws cloudfront create-invalidation --distribution-id "$DISTRIBUTION_ID" --paths "/*" --query 'Invalidation.Id' --output text)"
echo "CloudFront invalidation created: $INVALIDATION_ID"
aws cloudfront wait invalidation-completed --distribution-id "$DISTRIBUTION_ID" --id "$INVALIDATION_ID"
echo "CloudFront invalidation completed: $INVALIDATION_ID"

echo "Deployed to CloudFront: https://$DISTRIBUTION_DOMAIN"
if [[ -n "$DOMAIN_NAME" ]]; then
  echo "Custom domain: https://$DOMAIN_NAME"
fi
