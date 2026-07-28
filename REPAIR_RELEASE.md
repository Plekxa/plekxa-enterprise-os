# Plekxa shared-data repair release

This release fixes two confirmed issues from the previous full replacement:

1. Enterprise notification inserts no longer fail TypeScript compilation when generated Supabase types are stale.
2. `creator_profiles.user_id` now uses a full unique index, which is required for `ON CONFLICT (user_id)`.

## Database order

Run `supabase/migrations/007_creator_profile_unique_constraint_repair.sql` first.
Then rerun the migration that previously failed.

Do not rerun migration 002 unless you are rebuilding a fresh database.
