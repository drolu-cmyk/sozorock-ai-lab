# SozoRock AI Lab

A static, AWS-ready landing page for **SozoRock AI Lab**, a program of the SozoRock Foundation focused on helping communities, small businesses, public-sector partners, and local institutions learn, build, deploy, and govern AI safely.

**Recommended canonical URL:** `https://www.sozorockfoundation.org/ai-lab/`  
**Recommended standalone AWS launch URL:** `https://ai-lab.sozorockfoundation.org/`

The site keeps the high-end, art-directed, light-mode design direction from the original concept while shifting the copywriting into a nonprofit/civic AI capacity-building frame.

## What is included

```txt
site/                         Static website source
site/index.html               Main SozoRock AI Lab page
site/assets/css/styles.css    Visual system, layout, responsive styling
site/assets/js/main.js        Navigation, reveal animation, active section state
design/reference-images/      8 separate horizontal SVG section references
design/reference-collages/    Generated visual reference collages from the concept pass
docs/aws-hosting.md           AWS/CloudFront hosting guide
docs/design-system.md         Design and copy system notes
infra/cloudformation/         S3 + CloudFront infrastructure template
infra/iam/                    GitHub Actions deploy policy example
.github/workflows/            AWS deployment workflow
scripts/build.sh              Builds root and /ai-lab prefixed static outputs
scripts/deploy-aws.sh         CloudFormation + S3 sync + CloudFront invalidation
```

## Local preview

No build framework is required. This is a static site.

```bash
cd sozorock-ai-lab
npm run serve
```

Then open `http://localhost:4173`.

## Build

```bash
npm run build
```

This creates:

- `dist/` for standalone hosting at `ai-lab.sozorockfoundation.org`
- `dist-ai-lab-prefix/ai-lab/` for path hosting at `www.sozorockfoundation.org/ai-lab/`

## AWS recommendation

Use **S3 + CloudFront + Origin Access Control**.

For fastest clean launch, deploy to:

```txt
ai-lab.sozorockfoundation.org
```

For the nonprofit parent-domain path:

```txt
www.sozorockfoundation.org/ai-lab/
```

that path must be handled by the existing `www.sozorockfoundation.org` hosting layer. If the main site is already behind CloudFront, add a behavior for `/ai-lab/*` that points to this AI Lab S3 origin. If the main site is hosted elsewhere, either deploy as a subdomain first or update the main site host to proxy the `/ai-lab/` path.

See [`docs/aws-hosting.md`](docs/aws-hosting.md).

## Deploy with GitHub Actions

1. Create the AWS stack using `scripts/deploy-aws.sh` or the CloudFormation template.
2. Create a GitHub OIDC IAM role for this repo.
3. Add these repository variables/secrets:

```txt
AWS_ROLE_TO_ASSUME
AWS_REGION
AWS_S3_BUCKET
AWS_CLOUDFRONT_DISTRIBUTION_ID
```

Then pushes to `main` deploy the static site.

## Brand architecture

SozoRock Foundation remains the parent brand. The site references the related SozoRock program family:

- SozoRock Health
- SozoRock Meridian
- SozoRock AI Lab

## License

All visual direction, copy, and content in this repository are provided for SozoRock Foundation use. See [`LICENSE`](LICENSE).
