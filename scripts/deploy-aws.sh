#!/usr/bin/env bash
set -euo pipefail
export AWS_PAGER=""
STACK_NAME="${STACK_NAME:-sozorock-ai-lab}"
AWS_REGION="${AWS_REGION:-us-east-1}"
SITE_BUCKET_NAME="${SITE_BUCKET_NAME:?Set SITE_BUCKET_NAME}"
DOMAIN_NAME="${DOMAIN_NAME:-ai-lab.sozorockfoundation.org}"
CERTIFICATE_ARN="${CERTIFICATE_ARN:-}"
HOSTED_ZONE_ID="${HOSTED_ZONE_ID:-}"
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
bash scripts/render-cloudformation.sh "$TEMPLATE" >/dev/null
npm test
aws cloudformation validate-template --region "$AWS_REGION" --template-body "file://$TEMPLATE" >/dev/null
aws cloudformation deploy --region "$AWS_REGION" --stack-name "$STACK_NAME" --template-file "$TEMPLATE" --capabilities CAPABILITY_NAMED_IAM --no-fail-on-empty-changeset --parameter-overrides SiteBucketName="$SITE_BUCKET_NAME" DomainName="$DOMAIN_NAME" CertificateArn="$CERTIFICATE_ARN" HostedZoneId="$HOSTED_ZONE_ID" SenderEmail="$SENDER_EMAIL" InternalNotificationEmail="$INTERNAL_NOTIFICATION_EMAIL" FullApplicationUrl="$FULL_APPLICATION_URL" AllowedOrigin="$ALLOWED_ORIGIN" ApplicationRateLimit="$APPLICATION_RATE_LIMIT" ApplicationBurstLimit="$APPLICATION_BURST_LIMIT"
get_output(){ aws cloudformation describe-stacks --region "$AWS_REGION" --stack-name "$STACK_NAME" --query "Stacks[0].Outputs[?OutputKey=='$1'].OutputValue | [0]" --output text; }
DISTRIBUTION_ID="$(get_output DistributionId)"
BUCKET_NAME="$(get_output BucketName)"
aws s3 sync dist/assets/ "s3://$BUCKET_NAME/assets/" --delete --cache-control "public,max-age=31536000,immutable"
aws s3 sync dist/ "s3://$BUCKET_NAME/" --delete --exclude "assets/*" --cache-control "no-cache,no-store,must-revalidate"
INVALIDATION_ID="$(aws cloudfront create-invalidation --distribution-id "$DISTRIBUTION_ID" --paths '/*' --query 'Invalidation.Id' --output text)"
aws cloudfront wait invalidation-completed --distribution-id "$DISTRIBUTION_ID" --id "$INVALIDATION_ID"
echo "Deployment complete: https://$DOMAIN_NAME"
