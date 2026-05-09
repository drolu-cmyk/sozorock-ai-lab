# SozoRock AI Lab V1 patch notes

This patch implements the approved V1 site direction and application flow for `https://ai-lab.sozorockfoundation.org/`.

## Included files

- `site/index.html` - source-of-truth homepage design.
- `site/privacy/index.html` - Privacy route.
- `site/terms/index.html` - Terms route.
- `site/accessibility/index.html` - Accessibility route.
- `site/nondiscrimination/index.html` - Nondiscrimination route.
- `site/images/oluwabiyi-adeyemo.svg` - circular profile asset generated from the approved photo.
- `infra/cloudformation/cloudfront-s3-private.yml` - adds DynamoDB, Lambda, API Gateway, SES email flow, CloudFront `/api/*` routing, and extensionless URL rewrites.
- `scripts/deploy-aws.sh` - deploys stack and waits for CloudFront invalidation completion.
- `.github/workflows/deploy-aws.yml` - waits for invalidation and optionally smoke-tests the live domain.
- `infra/iam/github-actions-deploy-policy.json` - expanded example permissions for API/Lambda/DynamoDB/SES stack changes.
- `docs/application-email-flow.md` - how the short form, selected-applicant email, and SES setup work.

## Application flow

1. Visitor submits the short form.
2. Frontend posts to `/api/applications/start`.
3. Lambda stores the record in DynamoDB.
4. Applicant receives confirmation.
5. Internal reviewer receives a notification.
6. Selected applicants receive the full application link through the protected `/api/applications/selected` endpoint.

## Important production setup

- Verify `SenderEmail` in SES.
- Set `InternalNotificationEmail`.
- Set `AdminApiSecret`.
- Set `FullApplicationUrl` or provide `applicationUrl` when calling `/api/applications/selected`.
- Apply the CloudFormation template before relying on `/api/applications/start`.
- Merge/deploy through the existing AWS workflow after stack updates.
