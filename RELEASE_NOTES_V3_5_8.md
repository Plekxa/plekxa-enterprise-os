# Plekxa Enterprise OS v3.5.8 — Index Register Backup

- Adds **Export Index Register** to Rights & Registry → Indexes.
- Generates one `.xlsx` backup directly from live Supabase data.
- Workbook sheets: Indexes, Asset Memberships, Contributors, Certificates, Revenue Allocations, Backup Info.
- Export is authenticated and restricted to active Enterprise staff.
- No Cloudflare/R2 objects are copied; this is a structured rights/economics backup.
- No SQL migration required.
