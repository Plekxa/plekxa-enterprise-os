# Enterprise OS v3.7.9

- Hardened every current Asset contributor creation path against the production legacy `contributor_role` / `ppr_split` NOT NULL fields while retaining canonical `role_name` / `master_share`.
- Added a compatibility migration that synchronizes legacy and canonical contributor fields.
- Added top-level **Communication** to each Project Workspace.
- Project Overview now exposes **Open chat & files** as soon as any contributor workspace exists.
- Contributors list has a direct **Chat & files** action for every commission.
- Enterprise can message a creator and upload/remove creator-visible production/reference files without leaving the Project Workspace.
- Project production GET now returns the existing private commission conversation; no second messaging system was created.
- Existing Commission APIs, notification flow, R2 upload path and Creator Studio workspace remain authoritative.
