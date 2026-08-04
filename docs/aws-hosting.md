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
- CloudFront distribution with OAC, not public S3 website hosting
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

Repository configuration:

```txt
# Optional variable override; the workflow defaults to the dedicated role below.
AWS_ROLE_TO_ASSUME=arn:aws:iam::791860731989:role/GitHubActionsSozorockAiLabDeployRole
AWS_REGION=us-east-1

# Existing deployment secrets.
AWS_S3_BUCKET=your-site-bucket
AWS_CLOUDFRONT_DISTRIBUTION_ID=E1234567890
```

The deployment permissions are in `infra/iam/github-actions-deploy-policy.json`.

### Bootstrap or repair the dedicated role

The dedicated GitHub Actions role is configured in AWS account `791860731989`. The following command is retained as an idempotent recovery procedure if the OIDC trust policy or deployment permissions ever drift:

```bash
export AWS_ACCOUNT_ID=791860731989
export SITE_BUCKET_NAME=your-existing-ai-lab-bucket
export STACK_NAME=sozorock-ai-lab

# Default role name; one positional argument is the bucket.
bash scripts/configure-github-oidc-trust.sh "$SITE_BUCKET_NAME"

# Equivalent explicit form:
bash scripts/configure-github-oidc-trust.sh GitHubActionsSozorockAiLabDeployRole "$SITE_BUCKET_NAME" "$STACK_NAME"
```

The script creates the GitHub OIDC provider when missing, creates the dedicated role when missing, reconciles its trust policy, and attaches the checked-in deployment policy with the target bucket, account, and stack rendered into it. It prints the exact role ARN. The workflow already defaults to `arn:aws:iam::791860731989:role/GitHubActionsSozorockAiLabDeployRole`, so no role secret is required when the default role is used. Set the repository variable `AWS_ROLE_TO_ASSUME` only when intentionally using a different role.

After this one-time trust bootstrap, every push to `main` automatically validates, builds, deploys through CloudFormation and S3, invalidates CloudFront, and runs the production smoke tests. No AWS administrator credentials are stored in GitHub.

This command must be run with an AWS administrator identity that can manage IAM OIDC providers, roles, and inline policies. It does not change the application code or the Health repositories.

