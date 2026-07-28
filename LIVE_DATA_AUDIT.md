# Live Data Audit

All routed Enterprise pages now read/write through Supabase APIs.

Canonical shared tables: projects, creator_profiles, creator_applications, proposals, notifications, staff_members.
Operational modules: enterprise_records, partitioned by module.
Access control: access_roles.

Removed from routed code: localStorage persistence, demo creators, demo submissions, seed assets, seed finance, mock projects, placeholder notification popover.

Validation performed:
- TypeScript/TSX syntax transpilation across all source files: 0 diagnostics.
- Internal import resolution across all source files: 0 missing imports.
- External dependency manifest audit: all non-Node imports declared in package.json.
- Migration 008 is idempotent and creates the required live-data contract.

A complete Next.js build could not be run in the packaging environment because the package registry did not respond before timeout. Run npm install and npm run build locally before production deployment.
