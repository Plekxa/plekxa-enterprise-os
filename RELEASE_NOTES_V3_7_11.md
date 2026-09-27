# Plekxa Enterprise OS v3.7.11

- Resolves creator auth identity from `creator_profiles.user_id` before workspace activation and notifications.
- Repairs/activates the matching creator workspace on Plekxa countersign, including legacy workspaces linked by enterprise creator profile.
- Prevents creator notifications from using a creator-profile UUID where an auth-user UUID is required.
- Moves contract supporting-document uploads to the private `plekxa-internal` R2 bucket. Contract uploads no longer depend on `CLOUDFLARE_R2_PUBLIC_BASE_URL`.
- Preserves the v3.7.10 countersignature lifecycle.
