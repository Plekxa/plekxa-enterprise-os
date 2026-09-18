# Plekxa Enterprise OS v3.4.1
- Hardened asset_files/project_files/internal_files schema migration to prevent PostgREST schema-cache failures such as missing r2_bucket.
- Cloudflare R2 direct uploads now support single PUT up to 5 GiB and multipart uploads above 5 GiB with 100 MiB parts.
- Asset Registry accepts arbitrary file types including ZIP/RAR/video/audio and supports multi-file and folder selection.
- Artwork in Asset Registry is a real file upload, not a URL field.
- CMS visual/document fields now use real uploads to a public R2 media bucket rather than requiring pasted image/artwork URLs.
- Internal Team Files supports large files, multiple files and folder selection in plekxa-internal.
- Retired Experience route redirects to Projects and the legacy API returns 410.
- Added mobile/tablet responsive hardening for drawers, grids, tables and actions.
