# Plekxa Enterprise OS v1.12 — Full live-data replacement

1. Back up the current repository and Supabase database.
2. Replace the entire Enterprise OS project with this folder, preserving only your local `.env.local` file.
3. Run `supabase/006_enterprise_live_data.sql` once in Supabase SQL Editor.
4. Confirm Vercel has `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY`, `SUPABASE_SERVICE_ROLE_KEY`, SMTP variables and `NEXT_PUBLIC_STUDIO_URL`.
5. Run `npm install`, then `npm run build`.
6. Commit and deploy.

This release removes demo/localStorage persistence from Projects, Contracts, Assets, Experiences, Content, Newsroom, Marketing, Finance, Careers, Support, Activity, Settings and CRM. Applications, proposals, staff, creators and notifications use their canonical shared tables/APIs.
