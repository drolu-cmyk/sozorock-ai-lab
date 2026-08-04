# SozoRock AI Lab

Production source for **SozoRock AI Lab**, a free applied-AI learning program of **The SozoRock Foundation, Inc.**

- Production: <https://ai-lab.sozorockfoundation.org/>
- Curriculum: <https://ai-lab.sozorockfoundation.org/curriculum/>
- Foundation: <https://www.sozorockfoundation.org/>
- Runtime: AWS S3, CloudFront, Route 53, ACM, API Gateway, Lambda, DynamoDB, SES, and CloudWatch
- Software license: [MIT](LICENSE)
- Educational content license: [CC BY 4.0](LICENSE-CONTENT.md)

> Code is licensed under MIT. Curriculum, guides, templates, and educational content are licensed under CC BY 4.0 unless noted otherwise. Brand identity, participant information, identifiable photographs and recordings, policy publications, and third-party materials are excluded. See [NOTICE.md](NOTICE.md).

## Product direction

The site leads with the approved promise: **Before we automate, we decide.** Its editorial direction uses deep navy, ivory, amber, evergreen, and human-centered imagery. It excludes purple AI gradients, generic tool-first messaging, card grids, fake dashboards, invented metrics, unsupported testimonials, fake affiliations, and generic transformation claims.

## Structure

```text
site/                         Public website and generated legal pages
site/assets/                  Shared CSS, JavaScript, identity, and visual assets
site/.well-known/security.txt Vulnerability reporting contact
infra/cloudformation/parts/   Auditable CloudFormation source parts
scripts/legal-parts/          Auditable legal-page generator source parts
scripts/render-legal.sh       Builds public policy pages
scripts/render-cloudformation.sh Builds the deployment template
scripts/check-*.js            Content, SEO, accessibility, and security gates
.github/workflows/            Validation, CodeQL, and AWS deployment
```

## Local development

Requirements: Node.js 20+, npm, Bash, and Python 3.

```bash
npm ci
npm run serve
npm test
```

`npm test` regenerates policy pages and the CloudFormation template, checks approved copy and prohibited claims, validates internal links, SEO metadata, JSON-LD, sitemap, robots, accessibility conventions, strict-CSP compatibility, backend controls, and then builds `dist/`.

## AWS architecture

```text
Browser -> CloudFront -> private S3
                    -> API Gateway -> Lambda -> DynamoDB + SES
```

Controls include private S3 with Origin Access Control, encryption, versioning, DynamoDB point-in-time recovery and TTL, least-privilege Lambda permissions, same-origin application submission, JSON and size validation, honeypot and completion-time checks, API throttling, reserved concurrency, retained logs, AWS-IAM protection for the administrative route, TLS 1.2+, HSTS, strict CSP without `unsafe-inline`, clickjacking protection, restrictive referrer and permissions policies, and no-store API responses.

## Application endpoints

- `POST /api/applications/start` — public interest form, restricted to the production origin.
- `POST /api/applications/selected` — administrative invitation endpoint protected by AWS IAM and intended for SigV4-signed calls, not browsers.

Application records expire after approximately two years unless lawful operational needs require a different period. The public form warns users not to submit confidential or regulated information.

## Deployment

Pushes to `main` run validation, deploy the CloudFormation stack through GitHub OIDC, synchronize the site to S3, invalidate CloudFront, wait for invalidation, and run live route, metadata, and security-header smoke tests.

Required repository secret:

```text
AWS_S3_BUCKET
```

For the first custom-domain deployment, also set `AWS_ACM_CERTIFICATE_ARN` and
`AWS_ROUTE53_HOSTED_ZONE_ID` as repository secrets. Existing stacks reuse their
stored values automatically. `FULL_APPLICATION_URL` is optional.

The workflow defaults to the dedicated OIDC role in AWS account `791860731989`.
Only when intentionally deploying with another account or role, set this
repository variable (not a secret):

```text
AWS_ROLE_TO_ASSUME=arn:aws:iam::<account-id>:role/<role-name>
```

The production workflow also defaults to the verified active response-headers
policy. Set `EXISTING_RESPONSE_HEADERS_POLICY_ID` only when intentionally
deploying another stack or AWS account.

Recommended variables:

```text
STACK_NAME=sozorock-ai-lab
AWS_REGION=us-east-1
AI_LAB_DOMAIN=ai-lab.sozorockfoundation.org
ALLOWED_ORIGIN=https://ai-lab.sozorockfoundation.org
SENDER_EMAIL=contact@sozorockfoundation.org
INTERNAL_NOTIFICATION_EMAIL=contact@sozorockfoundation.org
APPLICATION_RATE_LIMIT=5
APPLICATION_BURST_LIMIT=10
```

## Search and sharing

Every indexable page has a unique title and description, canonical URL, Open Graph metadata, X Card metadata, one `h1`, valid JSON-LD, and crawlable internal links. The homepage publishes NGO, WebSite, WebPage, and EducationalOccupationalProgram schema. The site includes `robots.txt`, a canonical XML sitemap, manifest, favicon, social image, and custom 404 page.

Technical SEO cannot guarantee rankings. After deployment, verify the domain in Google Search Console, submit `https://ai-lab.sozorockfoundation.org/sitemap.xml`, inspect the canonical homepage, monitor coverage and enhancements, and request recrawling after material changes.

## Accessibility

The public target is WCAG 2.2 Level AA. Release review covers semantic structure, keyboard access, visible focus, image alternatives, labelled forms, live status messages, responsive layouts, reduced motion, zoom, and touch-target size. Automated checks support but do not prove conformance.

## Legal operation

The site publishes privacy, terms, cookies, acceptable-use, responsible-AI, accessibility, nondiscrimination, data-rights, security, copyright, media-consent, and grievance pages. These pages must remain consistent with deployed behavior. Counsel should review them before payments, minors, formal credentials, research, participant accounts, or materially different data processing are introduced.

## Brand and OpenAI

The parent identity is **SozoRock** and **AI Lab** is the program descriptor. Do not substitute another SozoRock program name. SozoRock AI Lab is independent and is not sponsored by or affiliated with OpenAI. The Lab may use third-party tools, including OpenAI products and Codex, where appropriate.

## Security and license

Report vulnerabilities through [SECURITY.md](SECURITY.md), `/security/`, or `/.well-known/security.txt`.

CodeQL runs on pull requests, pushes to `main`, and a weekly schedule. The workflow retains SARIF output as a 30-day artifact when repository code-scanning upload is unavailable.

Software is available under the [MIT License](LICENSE). Curriculum, guides, templates, and educational content are available under [CC BY 4.0](LICENSE-CONTENT.md), except where noted. Separate restrictions for identity, participant information, identifiable photographs and recordings, policy publications, and third-party materials are in [NOTICE.md](NOTICE.md).
