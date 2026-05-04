#!/usr/bin/env bash
set -euo pipefail

STACK_NAME="${STACK_NAME:-sozorock-ai-lab}"
AWS_REGION="${AWS_REGION:-us-east-1}"
SITE_BUCKET_NAME="${SITE_BUCKET_NAME:?Set SITE_BUCKET_NAME, e.g. sozorock-ai-lab-prod-ACCOUNTID}"
DOMAIN_NAME="${DOMAIN_NAME:-}"
CERTIFICATE_ARN="${CERTIFICATE_ARN:-}"
HOSTED_ZONE_ID="${HOSTED_ZONE_ID:-}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

bash scripts/build.sh

aws cloudformation deploy \
  --region "$AWS_REGION" \
  --stack-name "$STACK_NAME" \
  --template-file infra/cloudformation/cloudfront-s3-private.yml \
  --parameter-overrides \
    SiteBucketName="$SITE_BUCKET_NAME" \
    DomainName="$DOMAIN_NAME" \
    CertificateArn="$CERTIFICATE_ARN" \
    HostedZoneId="$HOSTED_ZONE_ID"

DISTRIBUTION_ID="$(aws cloudformation describe-stacks --region "$AWS_REGION" --stack-name "$STACK_NAME" --query "Stacks[0].Outputs[?OutputKey=='DistributionId'].OutputValue" --output text)"
BUCKET_NAME="$(aws cloudformation describe-stacks --region "$AWS_REGION" --stack-name "$STACK_NAME" --query "Stacks[0].Outputs[?OutputKey=='BucketName'].OutputValue" --output text)"
DISTRIBUTION_DOMAIN="$(aws cloudformation describe-stacks --region "$AWS_REGION" --stack-name "$STACK_NAME" --query "Stacks[0].Outputs[?OutputKey=='DistributionDomainName'].OutputValue" --output text)"

aws s3 sync dist/assets/ "s3://$BUCKET_NAME/assets/" --delete --cache-control "public,max-age=31536000,immutable"
aws s3 sync dist/ "s3://$BUCKET_NAME/" --delete --exclude "assets/*" --cache-control "no-cache,no-store,must-revalidate"
aws cloudfront create-invalidation --distribution-id "$DISTRIBUTION_ID" --paths "/*"

echo "Deployed to CloudFront: https://$DISTRIBUTION_DOMAIN"
if [[ -n "$DOMAIN_NAME" ]]; then
  echo "Custom domain: https://$DOMAIN_NAME"
fi
