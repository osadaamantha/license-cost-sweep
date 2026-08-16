# Config workbook contract — DRAFT, pending sign-off

**This is a provisional schema, not a confirmed one.** No column schema for the
per-tenant config workbook exists anywhere else in this repo's history. The columns
below are a reasonable starting point derived from what the confirmed business
requirements actually need (see `CLAUDE.md`), not something a client or MSP Blueshift
stakeholder has reviewed. Column names may still change — do not build against this as
if it were final.

## Columns

| Column | Type | Required | Meaning |
|---|---|---|---|
| `TenantId` | string (GUID) | Yes | The client tenant's Entra directory (tenant) ID. |
| `TenantDomain` | string | Yes | Primary verified domain, used to authenticate against this client tenant. |
| `ReportRecipients` | comma-separated string (email addresses) | No, defaults to empty | Overrides the default report distribution list for this tenant. Examples in this document use placeholder addresses (`user@client.example`) only — never real client or staff email addresses in this file or in fixtures. |
| `Enabled` | `Y`/`N` | No, defaults to `Y` | Whether this tenant is actively included in the sweep. |
| `Notes` | string | No | Free-text, human-readable only — never parsed. |

## Open questions (for the internal stakeholders, not to be resolved by guessing)

1. **Duplicate/overlapping licence SKU map**: which specific SKU pairs count as
   redundant has not been defined by the stakeholder. `Test-LicLicenseOverlap` accepts
   this as an injectable parameter (empty by default) — do not invent a plausible-looking
   table anywhere in this repo until this is confirmed.
2. **Service/automation account detection heuristic**: naming convention, `userType`, or
   a dedicated group membership — not yet confirmed. `Test-LicServiceAccount` accepts
   this as an injectable predicate (Unknown by default) for the same reason.
3. **Autotask ticket-creation credentials and target board**: not yet arranged. The
   confirmed ticketing shape (one ticket per client tenant, listing every finding) is
   settled; the actual API key and board are not.
4. **Report/ticket cadence**: daily or weekly has not been decided.
5. Where does this workbook live — a fixed SharePoint site/library path, or
   per-client-in-ITGlue? Not decided here; the eventual read adapter's site/path
   parameters will need real configuration once this is confirmed.

## Read-only guarantee

Loading this workbook is a read operation only — `Get-LicenseCostSweepConfiguration`
never writes back to it. Any correction to a client's configuration happens by editing
the workbook directly, not through this automation.
