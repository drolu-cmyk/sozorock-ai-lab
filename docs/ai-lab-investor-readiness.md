# SozoRock AI Lab investor-readiness note

## What changed

This update preserves the existing SozoRock AI Lab visual identity and extends the current one-page site with funding-ready, investor-readable sections. The site remains a premium static AWS-hosted page and does not introduce a new design system.

Key updates include:

- Refined hero copy for non-technical participants.
- Added clear experiential-learning language.
- Added a What participants build section.
- Added a scalable AI adoption platform section.
- Added early traction language based only on known facts.
- Added planned measurement language without fabricated metrics.
- Added business model and scale-path language.
- Added roadmap language using planned and target framing.
- Added About SozoRock Foundation section.
- Added Why SozoRock and build-capability sections.
- Added funder, venture partner, and strategic institution CTA language.
- Added privacy and consent-aware notes.
- Removed references to ministry and replaced them with daily life, work, business, education, nonprofit service, and community leadership.
- Preserved the legal name: The SozoRock Foundation Inc.
- Preserved EIN language: 39-4736725.

## Investor-readiness sections added

The updated site includes:

- Hero with practical one-month build promise.
- The real need.
- What participants build.
- Learn, Build, Deploy, Govern operating model.
- Product opportunity from local lab to scalable AI adoption platform.
- First customer language for non-technical builders.
- Early traction.
- How this can scale.
- Roadmap.
- About SozoRock Foundation.
- Why SozoRock.
- CTA for participants, funders, venture partners, and strategic institutions.

## Form handling approach

The public page currently uses email-based calls to action rather than a cosmetic embedded form. This avoids collecting applicant information through an unreliable static form.

Current contact path:

- contact@sozorockfoundation.org

Recommended production backend:

- Amazon API Gateway HTTP API
- AWS Lambda validation and routing layer
- Amazon DynamoDB submissions table
- Amazon SES notification to contact@sozorockfoundation.org
- CORS restricted to https://ai-lab.sozorockfoundation.org
- Throttling and rate limits at API Gateway
- Honeypot field and server-side validation
- No client-side AWS credentials
- No committed secrets

## Required environment variables for future backend

The static site does not currently require environment variables.

A future backend should use environment variables for:

- DYNAMODB_TABLE_NAME
- NOTIFICATION_EMAIL
- ALLOWED_ORIGIN
- SES_SOURCE_EMAIL

## Remaining gaps

- Production intake backend is not yet implemented.
- DynamoDB storage is not yet live.
- Admin dashboard is not yet implemented.
- Analytics are not yet implemented.
- Testimonials and participant examples should only be added after explicit consent.
- Real outcome metrics should only be added after measurement.

## Manual QA checklist

Before publishing major future updates, verify:

- No unsupported partnership claims.
- No fabricated metrics.
- No use of restricted or unwanted language.
- Mobile section badges show 12 / 12 correctly.
- Final sticky notes do not overlap on mobile.
- Footer remains clean.
- WhatsApp and Open Graph metadata are present.
- X and Instagram links open safely with rel attributes.
- Email links route to contact@sozorockfoundation.org.
- Life.Church link is labeled as AI for Real Life, not email.
- No secrets or API keys are present in the client.

## Deployment notes

The site deploys through GitHub Actions to AWS S3 and CloudFront. The build script copies the static site into dist and creates a CloudFront-compatible 404 page. The build script also copies the existing brand-aligned reference image into the deployed social preview path when present.

Current public URL:

https://ai-lab.sozorockfoundation.org/
