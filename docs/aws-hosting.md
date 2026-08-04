# AWS hosting guide

## Recommended launch path

Start with the standalone AWS subdomain:

```txt
https://ai-lab.sozorockfoundation.org
```

This is the fastest clean launch path because it can run as its own CloudFront distribution with a private S3 origin, CloudFront Origin Access Control, ACM TLS certificate, Route 53 alias, and GitHub Actions deployment workflow.

Then make the nonprofit path canonical when the main foundation site routing is ready:

```txt
https://www.sozorockfoundation.org/ai-lab/
```

A URL path such as `/ai-lab/` cannot be routed through DNS alone. It must be served by the routing layer behind `www.sozorockfoundation.org`, ideally through the existing foundation CloudFront distribution using a behavior for `/ai-lab/*` or through the foundation site's application/router.

## Recommended AWS architecture

```txt
Amazon S3 private bucket
        ↓
CloudFront distribution with OAC
        ↓
ACM TLS certificate in us-east-1
        ↓
Route 53 alias
        ↓
ai-lab.sozorockfoundation.org
```

Use this stack for the first launch:

- Amazon S3 private bucket for static files
- Amazon CloudFront distribution
- CloudFront Origin Access Control, not public S3 website hosting
- ACM TLS certificate in `us-east-1`
- Route 53 alias record for `ai-lab.sozorockfoundation.org`
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

Use this path after the foundation site routing layer is ready.

Run:

```bash
npm run build
aws s3 sync dist-ai-lab-prefix/ s3://YOUR_FOUNDATION_SITE_BUCKET/ --delete
```

Then ensure the existing `www.sozorockfoundation.org` CloudFront distribution serves `/ai-lab/*` from the bucket or prefix containing these files.

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

The deployment role trust policy must match this repository's GitHub OIDC subject. GitHub's immutable subject format uses the repository and owner IDs:

```txt
repo:drolu-cmyk@271617784/sozorock-ai-lab@1229146928:environment:production
```

If the workflow reports `Not authorized to perform sts:AssumeRoleWithWebIdentity`, apply the checked-in trust policy to the role named by `AWS_ROLE_TO_ASSUME` before rerunning the deployment:

```bash
AWS_ACCOUNT_ID=YOUR_ACCOUNT_ID bash scripts/configure-github-oidc-trust.sh YOUR_ROLE_NAME
```

The script renders the policy for the target account and preserves both legacy and immutable subject forms during the transition.
