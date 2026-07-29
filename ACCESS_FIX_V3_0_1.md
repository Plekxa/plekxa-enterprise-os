# Enterprise OS v3.0.1 access fix

- Master/Super Admin accounts now bypass route-level permission checks.
- Role-name matching tolerates spacing, hyphens, underscores and case differences.
- Nested routes inherit permission from their parent route.
- `/api/admin/me` now returns the database role's `is_master` value.
- Migration `009_super_admin_cms_access.sql` adds all current routes to the Super Admin record.
