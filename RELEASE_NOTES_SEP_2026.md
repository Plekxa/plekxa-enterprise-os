# Plekxa September 2026 alignment release

This coordinated release uses the September Platform Architecture & Operating Model as the canonical model and the team bug report as the repair list.

## Enterprise OS
- Removes Experience from current navigation/workflows; legacy data is preserved and old route redirects to Collections.
- Adds first-class Indexes, Plekxa Profiles, Releases, Collections and Index Certificates.
- Extends Asset Registry with role, mood, Index and primary Profile relationships.
- Fixes Contract creator lookup by using the live creator_profiles table and preserves full contract fields on save.
- Marketing scope is aligned to Asset / Release / Collection / Profile / External work rather than Experience.

## Creator Studio
- Proposal Format is now a dropdown using canonical format families.
- Legacy My Experiences route redirects to Active Projects and is removed from creator navigation.
- Proposal schema compatibility migration is included.

## Corporate
- Replaces the public Experiences rail/page with Collections.
- Music prefers the live Asset Release catalogue from Enterprise/Supabase.
- Shows and Movies remain editorial Content Studio records until their release types are represented in the release catalogue.
- Newsroom and Homepage Manager remain connected to Enterprise CMS.

## Database
Run `PLEKXA_PLATFORM_ALIGNMENT_SEP_2026.sql` once before deploying the new apps, then `PLEKXA_STUDIO_BUGFIX_SEP_2026.sql`.

The migration is additive: legacy Experience tables are not dropped, preventing data loss while the product moves to the canonical model.
