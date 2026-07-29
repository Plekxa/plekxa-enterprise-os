# Plekxa Enterprise OS v3.0.2 integration audit

## Restored regression
- `/analytics` again uses the full `AnalyticsWorkspace` dashboard with department views, report generation, CSV download, print/PDF flow and recent report history.
- The existing `/api/analytics/reports` database persistence endpoint is retained.

## Corporate CMS modules checked
- Homepage manager -> `cms_homepage_sections`
- Website pages -> `cms_pages`
- Navigation -> `cms_navigation`
- Media library -> `cms_media`
- Leadership -> `cms_leadership`
- Events -> `cms_events`
- Brand settings -> `cms_settings`
- Newsroom -> `cms_articles`
- Careers -> `cms_jobs`
- Contact centre -> `support_requests`

## Data handling fixes
- Navigation `open_new_tab` is converted to a real boolean before database writes.
- Event dates are converted to ISO timestamps and event slugs are generated when blank.
- Careers now supports both `open` and `published` public states.
- Super Admin/master-role bypass from v3.0.1 is retained.
- Additive indexes and public read policies are supplied in migration 010.
