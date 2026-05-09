#!/usr/bin/env bash
set -euo pipefail

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

bash scripts/build.sh

aws cloudformation deploy \
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
    AllowedOrigin="$ALLOWED_ORIGIN"

DISTRIBUTION_ID="$(aws cloudformation describe-stacks --region "$AWS_REGION" --stack-name "$STACK_NAME" --query "Stacks[0].Outputs[?OutputKey=='DistributionId'].OutputValue" --output text)"
BUCKET_NAME="$(aws cloudformation describe-stacks --region "$AWS_REGION" --stack-name "$STACK_NAME" --query "Stacks[0].Outputs[?OutputKey=='BucketName'].OutputValue" --output text)"
DISTRIBUTION_DOMAIN="$(aws cloudformation describe-stacks --region "$AWS_REGION" --stack-name "$STACK_NAME" --query "Stacks[0].Outputs[?OutputKey=='DistributionDomainName'].OutputValue" --output text)"

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
