# Enterprise OS v3.7.7 — Application decision + contract identity fix

- Removed the incorrect application identity rewrite introduced in v3.7.5/v3.7.6.
- `creator_applications.creator_id` and `creator_user_id` remain auth user IDs.
- Shortlist now stores the production-supported `under_review` status while the UI labels it Shortlisted.
- Acceptance resolves `creator_profiles.id` only where Enterprise needs a profile ID for workspaces/contributors.
- Companion SQL migration fixes the acceptance trigger so `contracts.creator_id` receives `creator_profiles.id` and `contracts.creator_user_id` receives the auth user ID.
