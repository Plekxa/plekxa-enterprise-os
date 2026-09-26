# Plekxa Enterprise OS v3.7.8

- Replaced the application-acceptance workspace `upsert(... onConflict: application_id)` with explicit lookup then update/insert, compatible with the production partial unique index on `creator_project_workspaces.application_id`.
- Project Hub now displays the database status `under_review` as `Shortlisted`.
- No schema migration is required for this release.
