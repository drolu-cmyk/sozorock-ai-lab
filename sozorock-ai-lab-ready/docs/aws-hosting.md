# AWS hosting guide

## Recommended URL strategy

Use both of these intentionally:

1. **Canonical nonprofit path:** `https://www.sozorockfoundation.org/ai-lab/`
2. **Fast standalone AWS launch:** `https://ai-lab.sozorockfoundation.org/`

A DNS record can point a subdomain to CloudFront directly. A URL path such as `/ai-lab/` cannot be delegated through DNS by itself; it must be routed by the web server or CloudFront distribution already serving `www.sozorockfoundation.org`.

## Best AWS architecture

- Amazon S3 private bucket for static files
- Amazon CloudFront distribution
- CloudFront Origin Access Control, not public S3 website hosting
- ACM TLS certificate in `us-east-1`
- Route 53 record for `ai-lab.sozorockfoundation.org`
- GitHub Actions OIDC deployment role

## Deploy as a standalone subdomain

```bash
export STACK_NAME=sozorock-ai-lab
export AWS_REGION=us-east-1
export SITE_BUCKET_NAME=sozorock-ai-lab-prod-ACCOUNTID
export DOMAIN_NAME=ai-lab.sozorockfoundation.org
export CERTIFICATE_ARN=arn:aws:acm:us-east-1:ACCOUNTID:certificate/xxxx
export HOSTED_ZONE_ID=Z1234567890

bash scripts/deploy-aws.sh
```

## Deploy under `www.sozorockfoundation.org/ai-lab/`

Run:

```bash
npm run build
aws s3 sync dist-ai-lab-prefix/ s3://YOUR_FOUNDATION_SITE_BUCKET/ --delete
```

Then ensure the existing `www.sozorockfoundation.org` CloudFront distribution serves `/ai-lab/*` from the bucket/prefix containing these files.

## GitHub Actions OIDC

Use the workflow in `.github/workflows/deploy-aws.yml`.

Repository variables/secrets:

```txt
AWS_ROLE_TO_ASSUME=arn:aws:iam::ACCOUNTID:role/GitHubActionsSozorockAiLabDeployRole
AWS_REGION=us-east-1
AWS_S3_BUCKET=your-site-bucket
AWS_CLOUDFRONT_DISTRIBUTION_ID=E1234567890
```

The minimum deployment permissions are in `infra/iam/github-actions-deploy-policy.json`.
