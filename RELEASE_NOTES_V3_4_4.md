# Plekxa Enterprise OS v3.4.4
- Automatically emails each issued Index Inclusion Certificate to the linked Asset contributor.
- PDF certificate is attached to the email and remains available in Creator Studio.
- Creates an in-app certificate notification for linked Creator Studio users.
- Records email delivery status, recipient, timestamp and failure reason.
- Idempotent delivery: already-sent certificates are not re-sent by assignment retries.
- Legacy contributors without a linked creator email are marked `no_recipient` rather than silently failing.
