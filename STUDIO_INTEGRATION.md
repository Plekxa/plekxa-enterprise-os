# Plekxa Studio → Enterprise OS integration

Both products should point to the same Supabase project. Studio sends completed submissions to:

`POST /api/studio/submissions`

Headers:
- `Content-Type: application/json`
- `x-plekxa-studio-key: <PLEKXA_STUDIO_INGEST_KEY>`

Required body fields:
- `submission_type`
- `title`
- `submitter_email`

Optional fields include `external_id`, `submitter_name`, `creator_profile_id`, and any additional structured fields. The entire request is retained in the `payload` JSON column so new Studio form fields can arrive without data loss.

Example body:

```json
{
  "external_id": "studio-application-123",
  "submission_type": "Asset submission",
  "title": "After Midnight",
  "submitter_name": "Amara Nwosu",
  "submitter_email": "amara@example.com",
  "creator_profile_id": null,
  "asset_type": "Audio Master",
  "contributors": []
}
```

The admin Applications page reads the same `studio_submissions` table. Accepted records can then be promoted into creator, project or asset records by a server workflow.
