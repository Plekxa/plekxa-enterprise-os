# Plekxa Enterprise OS v3.5.9 — Project-first Index architecture

- Analytics dashboard now reads live Supabase operational data; removed hard-coded demo KPIs.
- Indexes are 20 equal 5% positions and diversify by genre/mood instead of Flagship/Supporting/Niche classes.
- Creating a Project atomically reserves a permanent AST-###### Asset and assigns it to a diversified Index before applications/production.
- Project creation requires genre and mood; Projects show reserved Asset ID and Index code.
- Approved creator proposals can be converted into Projects, which then reserve Asset/Index.
- External commissions now create a Project first and reserve Asset/Index.
- Contract creation automatically links the Project's reserved Asset.
- Deliverable acceptance completes the pre-reserved Asset instead of creating a second Asset.
- Index register/export and certificate wording updated for genre/mood model.
- R2 multipart upload remains direct-to-R2 and supports large archives/project files with adaptive multipart sizing.
- Includes safe Supabase migration PLEKXA_PROJECT_FIRST_INDEX_V3_5_9_SEP_2026.sql.
