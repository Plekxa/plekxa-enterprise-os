# Enterprise OS v3.5.6 — R2 source integrity

- Marketing approved Asset library verifies every database file record with R2 HEAD before exposing access.
- Missing legacy/test objects are shown as Source missing instead of generating dead signed URLs.
- Downloads go through an authenticated Enterprise route that re-checks Asset approval and R2 existence immediately before signing.
- Signed download URLs expire after 5 minutes and are no longer embedded in the library API response.
- Marketing source refresh added.
- No SQL migration required.
