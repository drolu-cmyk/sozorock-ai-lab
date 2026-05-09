# SozoRock AI Lab application email flow

This patch maps the public short-interest form to `POST /api/applications/start` through CloudFront and API Gateway.

## Public interest endpoint

`POST /api/applications/start`

Expected JSON:

```json
{
  "firstName": "Ada",
  "lastName": "Lovelace",
  "email": "ada@example.com",
  "build": "I want to improve repeated reporting work.",
  "consent": true,
  "source": "sozorock-ai-lab-website",
  "applicationType": "interest_start",
  "cohort": "next"
}
```

The Lambda function:

1. Validates required fields.
2. Stores the submission in DynamoDB.
3. Sends a confirmation email to the applicant.
4. Sends an internal notification email to `InternalNotificationEmail`.

## Selected-applicant endpoint

`POST /api/applications/selected`

This endpoint is protected by the `x-admin-secret` header. It sends the full-application link only after a reviewer decides the applicant should continue.

Expected JSON:

```json
{
  "firstName": "Ada",
  "email": "ada@example.com",
  "applicationUrl": "https://example.com/full-application"
}
```

Required header:

```txt
x-admin-secret: <AdminApiSecret CloudFormation parameter>
```

If `applicationUrl` is omitted, the Lambda uses the `FullApplicationUrl` CloudFormation parameter.

## SES requirements

Before production, verify the `SenderEmail` identity in Amazon SES. If the AWS account is still in SES sandbox mode, recipient addresses must also be verified, or SES production access must be requested.

## Required CloudFormation parameters

- `SenderEmail`
- `InternalNotificationEmail`
- `FullApplicationUrl` optional but recommended
- `AdminApiSecret` required for selected-applicant emails

## Deployment note

The existing GitHub Actions deployment syncs static files and invalidates CloudFront. Infrastructure updates still require running `scripts/deploy-aws.sh` or otherwise applying `infra/cloudformation/cloudfront-s3-private.yml` to the stack before `/api/applications/start` works.
