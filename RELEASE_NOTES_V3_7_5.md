# Enterprise OS v3.7.5
- Canonicalises application creator identity before shortlist/accept/reject decisions.
- Ensures creator_id references creator_profiles.id, never auth.users.id.
- Prevents downstream contract foreign-key failures caused by legacy/malformed application creator IDs.
