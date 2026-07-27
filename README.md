# Plekxa Enterprise OS v1.0

A Next.js operating system for Plekxa Group, Plekxa Studio and the future Plekxa audience platform.

## What is included
- Enterprise command centre with attention queue, portfolio timeline, live activity and company pulse.
- Company management: staff, departments, teams, roles, permissions and access review structure.
- Creator CRM: identity, professional profile, verification, contracts, projects and earnings.
- Full project operations with list and Kanban views, milestones, deliverables, files, comments and approvals in the database model.
- Rights registry for assets, identifiers, contributors, ownership schedules, agreements and usage history.
- Finance workflow from revenue and distribution costs to creator share, tax, fees, net payable, approvals and payment references.
- Entertainment CMS, Experience management, Content Studio, Marketing, Relationship CRM, Support, Notifications and Analytics.
- Persistent interactive demonstration records stored in the browser until live Supabase tables are connected.
- Supabase migrations for the admin foundation and expanded Enterprise OS operational schema.

## Run locally
1. Install Node.js 20 or newer.
2. Copy `.env.example` to `.env.local` and add the Supabase URL and publishable key.
3. Run `npm install`.
4. Run `npm run dev`.
5. Open `http://localhost:3000`.

## Database
Run these files in Supabase SQL Editor in order:
1. `001_plekxa_admin_foundation.sql`
2. `002_create_first_admin.sql` after editing the user ID
3. `003_enterprise_os.sql`

## Production integration notes
The UI is intentionally usable immediately with realistic local demonstration data. The next implementation step is to replace each module's local storage adapter with Supabase queries and mutations, then tighten RLS policies from general admin read access to permission-key checks. Never expose the Supabase service-role key in browser code.
