# Plekxa Enterprise OS v3.4.5 — Audit Log Hardening

- Turns the existing Audit Log into a real database-backed operational audit trail.
- Records INSERT, UPDATE and DELETE events across consequential Enterprise tables.
- UPDATE events store field-level before/after values.
- Records are append-only and cannot be edited or deleted through normal database mutations.
- Sensitive credential-like fields are stripped before metadata is stored.
- Backend automation is labelled System when no human actor can be reliably resolved.
- Actor IDs are captured where Supabase/auth or created_by/updated_by/uploaded_by fields make attribution reliable.
- Adds indexes for recent-event, resource and actor lookup.
- Audit Log UI now exposes an Actor column and supports inspecting captured metadata through the existing record viewer.

Required migration: `PLEKXA_AUDIT_LOG_HARDENING_SEP_2026.sql`.
