# Cloudflare R2 storage

New media uploads use the private `plekxa-masters` R2 bucket through short-lived presigned URLs. R2 credentials remain server-only. The browser uploads directly to R2; Supabase stores metadata and the R2 object key.

Required Vercel environment variables:
- CLOUDFLARE_ACCOUNT_ID
- CLOUDFLARE_R2_ACCESS_KEY_ID
- CLOUDFLARE_R2_SECRET_ACCESS_KEY
- CLOUDFLARE_R2_BUCKET=plekxa-masters

Run `PLEKXA_R2_STORAGE_SEP_2026.sql` once before deploying these versions.
