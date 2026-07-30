# Invitation flow fix v3.2.3

This patch changes only the staff invitation and access-resolution flow.

- Invitation links always target `/accept-invite` on the deployed admin origin.
- Existing browser sessions are cleared before an invitation is exchanged.
- PKCE `code`, `token_hash`, and hash-token invitation formats are supported.
- Root invitation redirects preserve Supabase query/hash tokens.
- Invited staff cannot enter the dashboard before creating a password.
- Staff access is resolved against the authenticated user's exact ID.
- Missing roles no longer silently fall back to Viewer access.

No database migration is required.
