# Enterprise OS v3.1 targeted fixes

This release only addresses the reported admin problems.

1. Staff records can now be suspended or permanently deleted from People & Access. Permanent deletion also removes the linked Supabase Auth user.
2. Asset Registry now stores title, description, ISRC, UPC/EAN, ISWC, other identifiers, internal identifier, release date, licence dates, artwork, contract confirmation, restrictions and contributor rows with roles and ownership percentages.
3. Experiences now store target audience, description, artwork, budget, director, contributor ownership pool and linked asset IDs. The API calculates the fixed percentage per linked asset automatically.
4. Marketing campaigns can target either a Plekxa Experience or an external project.
5. Enterprise Notifications now only retrieves notifications whose audience is `enterprise`.
6. Website enquiries are synced from `support_requests` into `crm_contacts` by the included database trigger.
7. Invitation acceptance now explicitly exchanges the Supabase PKCE code before password creation, preventing an existing browser session from being mistaken for the invited user.

Run `supabase/migrations/011_admin_bugfixes.sql` in Supabase before deploying this version.
