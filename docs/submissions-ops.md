# AI Lab submissions operations

This site sends short interest forms to the AI Lab backend through the same public origin:

1. The homepage form posts JSON to `/api/applications/start`.
2. CloudFront routes `/api/*` to the API Gateway HTTP API.
3. API Gateway invokes the application Lambda.
4. The Lambda validates required fields, ignores honeypot submissions, writes accepted submissions to DynamoDB, and attempts SES email delivery.
5. The protected `/api/applications/selected` endpoint sends the full application link only when `x-admin-secret` matches `ADMIN_API_SECRET`.

## Website submission fields

The public form sends:

- `firstName`
- `lastName`
- `email`
- `build`
- `consent: true`
- `website` honeypot, when present
- `source: sozorock-ai-lab-website`
- `cohort: Cohort 02`

The public start endpoint must stay unauthenticated. The selected-applicant endpoint must stay protected by `ADMIN_API_SECRET`.

## Check recent submissions locally

Prerequisites:

- AWS CLI authenticated to the account that owns the `sozorock-ai-lab` CloudFormation stack
- permission to call `cloudformation:DescribeStacks`, `cloudformation:DescribeStackResources`, and `dynamodb:Scan`

Run:

```bash
bash scripts/check-submissions.sh
```

Defaults:

- `STACK_NAME=sozorock-ai-lab`
- `AWS_REGION=us-east-1`
- `RECENT_LIMIT=20`

Applicant values are redacted by default. To inspect full values intentionally:

```bash
SHOW_FULL_SUBMISSIONS=1 bash scripts/check-submissions.sh
```

## Run the smoke test

The smoke test posts a test record to the live site endpoint, then checks DynamoDB for the submitted email.

```bash
MODE=smoke-test bash scripts/check-submissions.sh
```

Override the endpoint if needed:

```bash
SMOKE_ENDPOINT=https://ai-lab.sozorockfoundation.org/api/applications/start MODE=smoke-test bash scripts/check-submissions.sh
```

Do not run this against production unless you intend to create a test submission record.

## GitHub Actions checks

Use **Check AI Lab submissions** from the Actions tab.

Modes:

- `list`: resolves the DynamoDB table and prints recent submissions with PII redacted by default.
- `smoke-test`: submits a test interest form to the live endpoint and confirms it appears in DynamoDB.

The workflow uses GitHub OIDC to assume `AWS_ROLE_TO_ASSUME`.

## Send selected applicants the full application

Local:

```bash
ADMIN_API_SECRET=... FULL_APPLICATION_URL=... bash scripts/send-selected-application.sh applicant@example.com "First"
```

With an explicit URL:

```bash
ADMIN_API_SECRET=... bash scripts/send-selected-application.sh applicant@example.com "First" "https://example.com/full-application"
```

GitHub Actions:

Use **Send AI Lab full application** from the Actions tab and enter:

- recipient email
- first name
- optional application URL override

The workflow reads `ADMIN_API_SECRET` and `FULL_APPLICATION_URL` from GitHub secrets and does not print the admin secret.

## Required GitHub secrets and variables

Secrets:

- `AWS_ROLE_TO_ASSUME`
- `AWS_S3_BUCKET`
- `AWS_ACM_CERTIFICATE_ARN`
- `AWS_ROUTE53_HOSTED_ZONE_ID`
- `FULL_APPLICATION_URL`
- `ADMIN_API_SECRET`

Variables:

- `AWS_REGION`, default `us-east-1`
- `STACK_NAME`, default `sozorock-ai-lab`
- `AI_LAB_DOMAIN`, default `ai-lab.sozorockfoundation.org`
- `ALLOWED_ORIGIN`, default `https://ai-lab.sozorockfoundation.org`
- `SENDER_EMAIL`, default `contact@sozorockfoundation.org`
- `INTERNAL_NOTIFICATION_EMAIL`, default `contact@sozorockfoundation.org`

## SES verification

SES can send only from verified identities while the account is in sandbox mode. Verify:

- `SENDER_EMAIL` is verified in SES in the deployment region.
- `INTERNAL_NOTIFICATION_EMAIL` can receive internal notifications.
- If SES is sandboxed, applicant recipient addresses must also be verified before test delivery succeeds.

A successful DynamoDB write does not guarantee SES delivery. The Lambda response includes email status booleans, and failed sends are logged as `SES_SEND_FAILED`.

## Common errors

- `Could not resolve ApplicationsTable`: check `STACK_NAME`, `AWS_REGION`, and CloudFormation describe permissions.
- `AccessDeniedException` on DynamoDB scan: add minimum read permission for the submissions table to the GitHub OIDC role.
- Smoke test accepted but no DynamoDB record found: check API Gateway route integration, Lambda logs, and DynamoDB `PutItem` permission.
- `401` from selected-applicant send: confirm `ADMIN_API_SECRET` is set in GitHub secrets and deployed to the stack.
- `Missing email or applicationUrl`: provide an application URL or set `FULL_APPLICATION_URL`.
- `Email not sent`: verify SES sender identity, sandbox status, and recipient eligibility.
