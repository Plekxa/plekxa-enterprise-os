# Consolidation audit

This release was compared file-by-file against v1.6. Every file present in v1.6 remains present in v1.8. The later account, search, staff and creator-management changes were layered on top rather than replacing the v1.6 operational modules.

Post-v1.6 additions verified:
- `app/(admin)/profile/page.tsx`
- `app/(admin)/search/page.tsx`
- `app/api/admin/me/route.ts`
- `app/api/admin/staff/*`
- `app/api/admin/creators/*`
- updated `app/api/admin/invites/route.ts`
- updated `components/Topbar.tsx`
- updated `components/PeopleAccessWorkspace.tsx`
- updated `components/CreatorDirectoryWorkspace.tsx`
- updated Supabase client/server helpers
- `supabase/migrations/006_staff_creator_management.sql`
- profile dropdown/global-search/destructive-action styles in `app/globals.css`
