# Plekxa Enterprise OS v3.7.6

Targeted application identity repair.

- Never writes NULL to creator_applications.creator_id.
- Resolves legacy application identity from canonical profile ID, creator_user_id, legacy auth UUID in creator_id, then exact applicant email.
- Repairs creator_user_id when absent.
- Stops with a clear 409 message instead of corrupting identity when no Creator Profile can be resolved.
- Preserves all v3.7.5 functionality.
