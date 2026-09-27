# Plekxa Enterprise OS v3.7.12

- Fixes contract Completed -> Active failures caused by creator-profile UUIDs reaching `notifications.recipient_id`.
- Adds a database compatibility guard that converts legacy `creator_profiles.id` recipients to canonical `auth.users.id` values without weakening the notification foreign key.
- Synchronises creator workspace status when a contract is changed between Active, Completed and Cancelled.
- Hardens Enterprise commission and deliverable notifications to resolve the creator's auth identity before notification/email delivery.
- Does not create duplicate contracts, workspaces, signatures, contributors or commissions when an existing contract is reactivated.
