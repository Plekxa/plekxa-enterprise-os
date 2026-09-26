# Plekxa Enterprise OS v3.7.1

Targeted production-schema compatibility hotfix.

- Project Hub creator queries now use the production `creator_profiles` schema: `id`, `user_id`, `legal_name`, `stage_name`, `email`.
- Removes invalid database selection of `creator_profiles.display_name`.
- Creator-facing display names prefer `stage_name`, then `legal_name`, then `email`.
- No database migration required.
- No Studio changes required.
