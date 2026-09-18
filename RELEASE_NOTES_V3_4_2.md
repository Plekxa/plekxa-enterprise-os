# Plekxa Enterprise OS v3.4.2 — Upload UX & Professional Polish

- Real byte-level upload progress for direct R2 uploads (not just completion percentages).
- Multipart progress updates while each chunk is transmitting.
- Per-file progress bars and percentage/status labels in Asset Registry.
- Multi-select uploaded files, Select all, and Delete selected.
- Bulk delete removes both R2 objects and Supabase records.
- Delete confirmation explicitly states Cloudflare R2 deletion.
- Upload controls are locked during active transfer to avoid accidental queue mutation.
- Preserves arbitrary file/folder upload support and private master storage architecture.
