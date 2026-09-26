# Plekxa Enterprise OS v3.6.3

- Fixes Project creation failing when production `projects.slug` is NOT NULL.
- Generates Project slugs in the Enterprise API.
- Adds a database-level slug trigger so older clients/proposal conversion cannot create a slug-less Project.
- Retains atomic Project → reserved Asset → Index assignment.
- Includes consolidated idempotent `PLEKXA_PROJECT_HUB_V3_6_3_SEP_2026.sql`.
