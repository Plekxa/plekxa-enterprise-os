# Plekxa Enterprise OS v3.4.0
September 2026 commissioning/index/finance hardening.

- Fixed 20-Asset automatic Index model: 4 Flagship @ 8%, 6 Supporting @ 6%, 10 Niche @ 3.2%.
- Indexes are automatically created/filled with concurrency protection; ordinary manual Index creation is read-only in UI.
- Formal Index Inclusion Certificate records and generated PDF certificates.
- Projects expose creator pay/budget, timed application windows, commission slots, Asset format and Index classification.
- Accepting multiple applicants creates separate private commission workspaces linked to one Project.
- Project milestone templates can carry due dates and payment amounts into each accepted workspace.
- Commission messaging and email notification hooks.
- Deliverable Review inbox: pending work is not an Asset until accepted; acceptance creates AST record, copies authoritative accepted files under AST R2 prefix, assigns Index and issues certificates.
- External/A-list commission path bypasses Creator Studio while preserving internal audit/workflow.
- Creator pitch approval creates a private assigned project/workspace rather than reopening it for applications.
- Asset-level finance ledger with Index-period pooling and creator allocation calculations.
- Separate `plekxa-internal` R2 storage UI for operational/team files.
- Existing `plekxa-masters` R2 direct-upload architecture retained.
