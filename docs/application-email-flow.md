# SozoRock AI Lab application email flow

The public interest form posts through CloudFront to `POST /api/applications/start`. The administrative invitation route is `POST /api/applications/selected` and is protected by AWS IAM at API Gateway. There is no browser-admin secret.

## Public interest endpoint

`POST /api/applications/start`

The request must come from `https://ai-lab.sozorockfoundation.org`, use `application/json`, stay below the API payload limit, and include a valid form start timestamp. The browser also sends the hidden `website` honeypot field.

Required fields:

```json
{
  "firstName": "Ada",
  "lastName": "Lovelace",
  "email": "ada@example.com",
  "build": "I want to improve repeated reporting work.",
  "consent": true,
  "formStartedAt": "2026-08-24T18:00:00.000Z",
  "applicationType": "participant-interest"
}
```

`applicationType` may be `participant-interest` or `organization-interest`. Organization inquiries also require `roleOrOrganization`. Optional fields are bounded and sanitized before storage.

The Lambda:

1. Enforces origin, method, content type, payload size, honeypot, and form-timing controls.
2. Validates and sanitizes submitted fields.
3. Writes the submission to the encrypted DynamoDB table using a conditional put and a two-year TTL.
4. Sends a confirmation email to the applicant through Amazon SES.
5. Sends a minimal internal notification to the configured Foundation recipient.
6. Returns no-store responses with a request ID and does not log submitted form contents.

API Gateway applies request throttling. The Lambda role can write only the application table and send through the configured SES identity.

## Selected-applicant endpoint

`POST /api/applications/selected`

This route uses `AWS_IAM` authorization. Calls must be SigV4-signed by an authorized internal AWS principal; it is not a browser route and has no shared-secret header.

Expected JSON:

```json
{
  "firstName": "Ada",
  "email": "ada@example.com",
  "applicationUrl": "https://example.com/full-application"
}
```

If `applicationUrl` is omitted, the Lambda uses the configured `FullApplicationUrl`. The URL must be HTTPS.

## SES and deployment

The sender identity must be verified in Amazon SES and the account must be able to send to the intended recipients. Deployment uses `scripts/deploy-aws.sh`, which renders the current template from `infra/cloudformation/parts/template.part-*`, validates it, preserves existing stack values when optional deployment inputs are omitted, deploys the stack, synchronizes the site, invalidates CloudFront, and waits for invalidation completion.

The canonical architecture and control checklist are documented in `docs/backend-intake.md`.
