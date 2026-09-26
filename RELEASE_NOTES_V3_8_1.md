# v3.8.1

- Fixes Vercel TypeScript failure in `app/api/work-assignments/route.ts`.
- Separates the authenticated current staff member from the staff-directory array so `Assigned to me` uses the correct `staff_members.id`.
- No database migration required.
