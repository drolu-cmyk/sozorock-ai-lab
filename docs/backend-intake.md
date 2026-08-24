# SozoRock AI Lab intake backend

## Production contract

The AI Lab intake path is a server-side AWS workflow. The public site does not email directly and does not expose AWS or model credentials.

```text
Browser
  -> CloudFront
  -> API Gateway HTTP API
  -> Lambda
  -> DynamoDB
  -> Amazon SES
```

Public intake uses `POST /api/applications/start`. Internal invitation delivery uses `POST /api/applications/selected` with `AWS_IAM` authorization.

## Data and abuse controls

The public route enforces the production origin, POST plus JSON, a bounded payload, required-field validation, field-length limits, sanitization, a hidden honeypot, and minimum/maximum form-completion timing. API Gateway applies rate and burst limits.

DynamoDB uses on-demand capacity, server-side encryption, point-in-time recovery, a two-year TTL, and conditional writes. The Lambda role is limited to writing the intake table, writing its retained log stream, and sending email through the configured SES identity. Application responses are no-store and operational logs do not include submitted form contents.

The public form warns people not to submit confidential or regulated information. New data fields must not be added without updating the privacy notice, validation rules, retention rationale, and tests.

## Email

After a valid submission, the backend sends a receipt to the applicant and a bounded internal notification to the configured Foundation recipient. Email failure is surfaced in the response metadata rather than being represented as a successful delivery.

The selected-applicant route is not public. API Gateway requires AWS IAM and callers must use an authorized SigV4-signed request. There is no shared browser-admin secret.

## Infrastructure source of truth

CloudFormation source is split under:

```text
infra/cloudformation/parts/template.part-*
```

`scripts/render-cloudformation.sh` concatenates those parts into a deployable template. `scripts/deploy-aws.sh` renders to a temporary file, validates the template, preserves existing stack parameters when optional deployment inputs are absent, applies the stack, synchronizes the static site, invalidates CloudFront, and waits for completion.

Do not deploy an old checked-in combined template. The parts plus renderer are the authoritative infrastructure definition.

## Runtime

The application Lambda uses the supported `nodejs24.x` runtime. Runtime changes must be checked against the current AWS Lambda supported-runtime schedule before deployment.

## Release checks

A release is acceptable only when all of the following are true:

- the public form posts to `/api/applications/start`, not `mailto:`;
- required fields are validated server side;
- origin, content type, payload size, honeypot, and timing checks remain active;
- submissions are written to the encrypted DynamoDB table with TTL;
- applicant and internal transactional email use Amazon SES;
- API Gateway throttling remains configured;
- `/api/applications/selected` remains `AWS_IAM` protected;
- no API key or administrative credential is exposed to the browser;
- the UI presents clear success and failure states;
- infrastructure rendering and repository security checks pass;
- production verification confirms the deployed route and security headers.
