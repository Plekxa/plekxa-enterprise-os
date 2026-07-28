# Production schema alignment

This release was rebuilt against the supplied production audit of 75 public tables, their columns, indexes, constraints, RLS policies, 21 functions and 23 triggers.

No new database migration is required for this release. Do not run the obsolete `008_complete_live_data_contract.sql.obsolete.txt`; it was based on guessed columns and is retained only as history.

Enterprise modules use the existing canonical tables:
- Projects: `projects`
- Contracts: `contracts`
- Assets: `asset_registry`
- Experiences: `experiences`
- Content: `content_items`
- Newsroom: `cms_articles`
- Marketing: `marketing_campaigns`
- Finance: `revenue_entries`
- Careers: `cms_jobs`
- Support: `support_requests`
- CRM: `crm_contacts`
- Analytics: `analytics_reports`
- Activity: `admin_audit_logs`
- Settings/roles: `access_roles`

Creator notification preferences are stored as user-owned records in the existing `enterprise_records` table, avoiding an unverified `creator_settings` table.
