# Plekxa Enterprise OS v3.2 — Targeted fixes

This release is limited to the requested operational fixes.

## Included

- Experience assets are selected from the Asset Registry through a searchable picker.
- Add/remove controls replace comma-separated asset IDs.
- Maximum of 20 assets per experience, enforced in both UI and database.
- Contributor ownership pool is divided automatically across selected assets.
- Asset Registry supports real uploads for audio, video, artwork, stems and documents through Supabase Storage.
- Asset file metadata is stored in `asset_files` for future catalogue and streaming use.
- Contracts can link to projects, experiences, assets and creators, and track counterparties, dates, amounts, signed documents and statuses.
- Accepted creator applications now expose project milestones, deliverables and uploaded files in the admin drawer.
- Finance accounting periods now use start and end dates.
- Homepage Manager schema is hardened around `section_key`, `display_order` and published status so the Corporate website can query the same records.

## Required deployment order

1. Run `supabase/migrations/012_streaming_foundation_fixes.sql` in Supabase SQL Editor.
2. Deploy this Enterprise OS build.
3. Confirm the `asset-media` Storage bucket exists (the migration creates it).
4. Test one asset upload, one experience with two assets, one contract, and one accepted creator application.

## Build verification

All changed TypeScript and TSX files passed TypeScript syntax transpilation. A full Next.js build could not be executed in the packaging environment because its npm mirror does not contain `@supabase/ssr`.
