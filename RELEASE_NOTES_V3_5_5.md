# Enterprise OS v3.5.5 — schema integrity + commission workspace
- Repairs production proposal status constraint vocabulary.
- Repairs contracts.creator_id foreign key to canonical creator_profiles.id.
- Adds explicit staff actor attribution for live Enterprise mutations and commission messages.
- Consolidates commission operations into Overview, Deliverables, Files, Conversation and Personnel tabs.
- Keeps Deliverable Review as a cross-company review inbox rather than a parallel workspace.
- Verifies R2 reference objects before creating DB records and before presenting download links; stale records now show a recoverable missing-file state instead of a Cloudflare XML error.
