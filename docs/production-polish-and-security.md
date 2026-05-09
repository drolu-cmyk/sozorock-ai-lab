# SozoRock AI Lab production polish and security pass

## SEO and sharing
- Homepage title updated to `SozoRock AI Lab | Build Useful AI Systems`.
- Meta description targets practical AI systems, repeated work, workflows, deployment review, and measurable results.
- Open Graph and Twitter Card tags point to `/assets/img/social-preview.png` for WhatsApp, iMessage, LinkedIn, X, and SMS previews.
- `robots.txt` and `sitemap.xml` added at site root.
- `site.webmanifest`, `favicon.ico`, `favicon.svg`, Apple touch icon, and 192/512 app icons added.
- Structured data added for Organization, WebSite, Person, EducationalOccupationalProgram, WebPage, and BreadcrumbList.

## Profile image
- Replaced the vector placeholder with optimized portrait assets:
  - `/images/oluwabiyi-adeyemo.jpg`
  - `/images/oluwabiyi-adeyemo.webp`
- Leadership profile uses a subtle SozoRock-branded circular frame.

## API and security
- CloudFront now maps `/api/*` to API Gateway while static pages remain private S3 behind Origin Access Control.
- CORS is restricted by `AllowedOrigin` instead of wildcard `*`.
- Form includes a honeypot field and the Lambda rejects bot-like submissions.
- Lambda validates email, required fields, consent, and max lengths before DynamoDB/SES operations.
- API responses include no-store cache headers.
- CloudFront response headers include HSTS, CSP, frame protections, referrer policy, content type protection, and permissions policy.
- DynamoDB table has TTL enabled for long-term data hygiene.

## Deployment
- GitHub Actions now calls `scripts/deploy-aws.sh`, so infrastructure and static assets deploy together.
- Deploy script updates CloudFormation, syncs S3 assets, syncs HTML/root files, creates a CloudFront invalidation, and waits for completion.

## Required repository secrets and variables
Secrets:
- `AWS_ROLE_TO_ASSUME`
- `AWS_S3_BUCKET`
- `AWS_ACM_CERTIFICATE_ARN`
- `AWS_ROUTE53_HOSTED_ZONE_ID`
- `FULL_APPLICATION_URL`
- `ADMIN_API_SECRET`

Variables:
- `AWS_REGION` defaults to `us-east-1`
- `AI_LAB_DOMAIN` defaults to `ai-lab.sozorockfoundation.org`
- `SENDER_EMAIL` defaults to `contact@sozorockfoundation.org`
- `INTERNAL_NOTIFICATION_EMAIL` defaults to `contact@sozorockfoundation.org`
- `ALLOWED_ORIGIN` defaults to `https://ai-lab.sozorockfoundation.org`

## SES requirement
The sender email must be verified in SES before applicant/internal email will send.
