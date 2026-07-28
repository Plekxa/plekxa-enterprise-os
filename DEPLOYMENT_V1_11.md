# Plekxa Enterprise OS v1.11 deployment

## Important
Run the matching `supabase/005_profile_identity_notifications.sql` once before deploying. Do not rerun migration 002.

## What changed
- Applications identify creators from `creator_profiles`, Supabase Auth metadata, Auth email, or the application snapshot.
- Accept, shortlist and reject update the shared row and create a creator notification.
- Reject requires a reason.
- Application decisions attempt a transactional SMTP email and report whether email or in-app notification succeeded.
- Proposals now use live database data instead of module demo data.
- Proposal approve/hold/reject creates notifications and attempts email delivery.
- Applications component no longer imports `lucide-react`.

## Vercel environment variables
Existing: `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY`, `SUPABASE_SERVICE_ROLE_KEY`.

Transactional mail: `SMTP_HOST`, `SMTP_PORT`, `SMTP_SECURE`, `SMTP_USER`, `SMTP_PASS`, `SMTP_FROM`, `NEXT_PUBLIC_STUDIO_URL`.

Example: `SMTP_FROM=Plekxa <no-reply@plekxa.com>`.

## Two separate email systems
1. Application/proposal decision emails are sent by Enterprise OS using the SMTP variables above.
2. Signup, password-reset and confirmation emails are sent by Supabase Auth. Configure the same provider separately in Supabase Dashboard > Authentication > SMTP Settings and change the sender name/address there. Vercel SMTP variables do not alter Supabase Auth emails.

## Deploy
1. Back up Supabase.
2. Run migration 005.
3. Copy this folder into the Enterprise OS repository, replacing matching files only.
4. Add the SMTP environment variables in Vercel for Production, Preview and Development as needed.
5. Run `npm install` (adds `nodemailer`) and `npm run build` locally.
6. Commit and push.
7. Test an application acceptance/rejection and a proposal decision with a test account.
