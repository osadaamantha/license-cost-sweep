---
name: graph-exchange-readonly
description: Author or review PowerShell code that reads Microsoft Graph or Exchange Online data for the licence-cost-sweep runtime. Use for licence-waste detection, disabled-account detection, never-signed-in detection, multi-tenant authentication, and throttling/retry behavior against these APIs.
---

# Graph & Exchange Read-Only Access

This is the core runtime and the highest-risk area in the project — it's the only code that touches live client tenants. Nothing here exists yet; this skill sets the pattern for the first implementation as much as it reviews later ones. See `CLAUDE.md` for the non-negotiable safety rules this skill implements, and `license-cost-safety` for the surrounding operational rules.

## Authentication

- App-only, certificate-based auth only — never a client secret, never interactive/delegated auth in runtime code. The runtime is a **Linux container**, so `-CertificateThumbprint` (Windows-only — it resolves against the Windows certificate store) is not available: use `Connect-ExchangeOnline -Certificate <X509Certificate2>` built in memory from the Key Vault secret bytes. `Connect-MgGraph -ClientId -Certificate -TenantId` the same way. Never `-Interactive` or `-DeviceCode`. (`-CertificateThumbprint` remains valid for `Connect-MgGraph` on Windows dev workstations only — never assume it works inside the runtime image.)
- The certificate's private key is retrieved from Key Vault via the job's managed identity at runtime — never written to disk, never logged, never embedded in a fixture.
- One connection per client tenant. Fully disconnect (`Disconnect-ExchangeOnline`, `Disconnect-MgGraph`) before moving to the next tenant — a lingering session from tenant A must never serve a call intended for tenant B.

## Least-privilege scope

- Microsoft Graph: read-only application permissions only — `User.Read.All`, `Directory.Read.All`, `Organization.Read.All`, `AuditLog.Read.All` (needed for sign-in activity — see below), or narrower if a narrower scope covers the need. Never request a `.ReadWrite` or `Mail.Read` scope without a stated reason (this runtime doesn't need mailbox content).
- Exchange Online: access restricted via an application access policy scoped to only what's needed; never request a scope broader than the mailboxes actually being audited.
- If a permission or field's exact name/behavior is uncertain, say so and flag it rather than guessing — a wrong Graph/EXO permission is a production auth failure at 3am for someone else, not a compile error now.

## Read-only enforcement

- Allowed cmdlet shape: `Get-*` only (`Get-Mailbox`, `Get-EXOMailbox`, `Get-MgUser`, `Get-MgSubscribedSku`, `Get-MgUserLicenseDetail`). Never `Set-`, `New-`, `Remove-`, `Enable-`, `Disable-`, or `Update-` against Exchange or Graph in runtime code — this is enforced by `/safety-scan` but don't rely on the scan alone; it's a design constraint, not a lint afterthought.
- This is easy to get wrong for this specific project: under **group-based licensing**, `Remove-MgGroupMemberByRef` / `Remove-MgUserMemberOf` *is* a licence revocation even though the cmdlet name doesn't mention licences. Treat group-membership mutation cmdlets as licence-mutation cmdlets for the purposes of this rule.
- Onboarding/administration scripts that legitimately need mutation (e.g. initial app consent, certificate rotation) live outside the runtime image and are clearly named/located so they're never mistaken for runtime code.

## Data sources for the three waste categories

- **Tenant SKU inventory (cost basis)**: `Get-MgSubscribedSku` for `prepaidUnits`/`consumedUnits`/`servicePlans` per SKU. Microsoft Graph does **not** expose licence pricing — the cost basis is an external input (CSP/Partner Center price list, a maintained CSV, or ITGlue) and must be flagged as a dependency, not invented or hardcoded.
- **Disabled accounts with paid licences**: `Get-MgUser -Property accountEnabled,assignedLicenses,licenseAssignmentStates` — an account with `accountEnabled: $false` and a non-empty `assignedLicenses` is the finding. Check `licenseAssignmentStates[].assignedByGroup`: a licence assigned via group membership needs the group edited, not `Set-MgUserLicense`, to remove — and per the enforcement note above, that group edit is itself a mutation this runtime must never perform.
- **Shared mailboxes with unnecessary licences**: `Get-EXOMailbox -RecipientTypeDetails SharedMailbox` cross-referenced with `Get-MgUserLicenseDetail` for that mailbox's account. A shared mailbox legitimately needs a licence above 50 GB or when placed on litigation hold/in-place archive — check mailbox size and hold status before flagging it as waste, not just presence of a licence.
- **Licensed users who have never signed in**: `Get-MgUser -Property signInActivity,createdDateTime,userType` plus `Get-MgUserLicenseDetail`. `signInActivity` requires the `AuditLog.Read.All` permission **and Entra ID P1/P2 in the client tenant** — if a tenant lacks P1/P2, this field is unavailable there and the finding is `Unknown` for that tenant, not absent. `lastSignInDateTime = null` is itself ambiguous (never signed in vs. beyond Entra's retention window) — treat it as `Unknown`, never assert "never logged in" from a null value alone.

## Resilience

- Wrap calls in bounded retry with exponential backoff on 429/throttling responses (Graph `Retry-After` header, EXO throttling errors) — never a tight retry loop, never an unbounded one.
- A single client tenant's failure must not stop the run for other tenants — catch, record the failure against that tenant, continue.
- Never log mailbox contents, subjects, or recipient addresses beyond what a report legitimately needs; treat tenant identifiers, mailbox addresses, and licence cost figures as sensitive in logs.
