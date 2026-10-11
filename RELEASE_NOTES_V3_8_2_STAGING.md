# Enterprise OS v3.8.2 — staging candidate, NOT production certified

Source baseline: Enterprise v3.8.1. Creator Studio v2.4.11 unchanged.

## Implemented in this source package
- New **Creative Programmes** page at `/creative-programmes` and authenticated management API at `/api/creative-programmes` for draft programme creation, listing, draft castings and management edits. Existing `/commissions` remains untouched (legacy creator engagements).
- Additive SQL migration for programme, casting, application, membership, assignment and budget commitment records. Legacy projects gain a nullable `creative_commission_id`.
- Membership activation trigger checks matching contract, auth/profile identity and both signatures.
- Serialized budget commitment RPC rejects spending beyond approved budget; no index accounting or payouts changed.
- Contract status PATCH now calls a transactional SQL RPC for supported Active/Completed/Cancelled transitions, instead of updating status without a workspace operation. The UI sends status-only requests when changing status.
- Existing notification trigger fix supplied separately remains necessary; this package does not overwrite it.

## Not implemented / not verified
- Creator Studio casting discovery/application/onboarding UI, commission lead permission scopes, creator-facing commission workspace, asset approvals, automatic assignment, index engine. The database scaffolding alone does not deliver these workflows.
- Production Next.js build, Supabase integration and end-to-end tests **not run**. Dependency installation was previously blocked by missing packages and network timeout.
- Actual live Supabase table constraints/RLS/trigger ordering not fully inventoried. SQL must be reviewed in staging first; do not apply to production blindly.
- Existing Enterprise navigation may not link to the new route; it can be opened directly.
- Contract transitions via this RPC are deliberately restricted. Other transitions require existing signing flows.
- On completion, legacy workspace status is not changed until actual workspace status CHECK constraint is verified. Reactivation updates/creates workspace as active.

**Deployment status: BLOCKED.** Do not upload this ZIP to production or execute migration on production without staging verification. It is a concrete source candidate for further engineering, not a claim that all requested changes are finished.
