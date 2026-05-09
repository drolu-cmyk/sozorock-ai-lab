# SozoRock AI Lab V2 production polish patch

This patch focuses on production readiness after the V1 redesign went live.

Included:
- SEO metadata, canonical URL, Open Graph, Twitter Card, schema.org JSON-LD.
- WhatsApp/SMS/social preview image at `/assets/img/social-preview.png`.
- Real favicon support: `/favicon.ico`, `/favicon.svg`, manifest, Apple icon, 192/512 icons.
- `robots.txt` and `sitemap.xml`.
- Optimized Oluwabiyi Adeyemo portrait assets in JPG and WebP.
- Hardened CloudFront security headers.
- API CORS restricted to the AI Lab origin.
- Lambda input validation and honeypot field.
- DynamoDB TTL for application data hygiene.
- GitHub Actions deploy now runs the full infrastructure + site deploy script.
