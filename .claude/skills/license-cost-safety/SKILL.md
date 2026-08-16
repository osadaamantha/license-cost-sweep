---
name: license-cost-safety
description: Keep the multi-tenant licence-cost sweep implementation read-only, tenant-safe, and secret-safe. Use for Exchange, Microsoft Graph, SharePoint, ITGlue, Storage, Autotask, report, and orchestration work.
---

# License Cost Safety

The deployed surface this applies to does not exist yet — the intended shape mirrors the sibling mailbox-audit-sweep repo: a Container Apps Job (planned name `caj-liccost-daily`), reading from a Key Vault (planned name `kv-liccost-prod`, via `KEY_VAULT_URI` + `AZURE_CLIENT_ID` env vars and the job's managed identity), writing to `reports`/`run-state` blob containers on a planned storage account (`stliccostprod`). Update this paragraph once that infrastructure is actually deployed — don't let it drift into describing resources that were never created. See `CLAUDE.md` for the non-negotiable rules this skill exists to enforce.

Most of this project's output is "licences you should remove or review" — that makes the read-only boundary more load-bearing here than in a report-only audit, since several findings are one API call away from being actioned directly instead of going through a change ticket. Shared-mailbox findings specifically are "needs manual review," not a removal verdict — see `graph-exchange-readonly`, don't let runtime code collapse that distinction into an auto-action.

1. Treat the runtime as read-only for Microsoft 365, Exchange, and Entra ID configuration. Do not add `Set-`, `New-`, `Remove-`, `Enable-`, `Disable-`, or `Update-` mutation cmdlets to runtime code — explicitly including `Set-MgUserLicense`, `Set-MsolUserLicense`, `Set-AzureADUserLicense`, `Update-MgUser`, and `Set-Mailbox`. **One confirmed exception**: creating an Autotask ticket per client tenant is an intended side effect of this runtime, not a violation — keep that call path isolated in its own adapter, the only mutating code anywhere in the runtime.
2. Treat group-membership mutation as licence mutation: `Remove-MgGroupMemberByRef` and `Remove-MgUserMemberOf` revoke a licence under group-based assignment even though neither cmdlet name says "license" — ban these from runtime code for the same reason as the cmdlets in point 1.
3. Keep onboarding and infrastructure administration separate from the production runtime image.
4. Isolate each client tenant: authenticate independently, use tenant-specific configuration, continue after a client failure, and never combine client report data or tickets.
5. Retrieve secrets only from Key Vault via the managed identity. Never place tokens, private keys, credentials, mailbox contents, subjects, or client spreadsheets in source, logs, fixtures, or prompts.
6. Classify missing or unavailable evidence as `Unknown` — this applies especially to sign-in activity in tenants without Entra ID P1/P2 (see `graph-exchange-readonly`). Do not make a waste finding from absent or assumed data. Note: licence pricing is out of scope for v1 entirely (see `CLAUDE.md`), not a field that needs `Unknown`-handling.
7. Make report/ticket creation idempotent with per-client/per-run state in `run-state`, and retain partial failure records rather than dropping them.
8. There is no CI in this repository to run an automated mutation-cmdlet scan. Run `/safety-scan` (`.claude/commands/safety-scan.md`) instead whenever runtime, Exchange, or Graph code changes — it greps for prohibited mutation cmdlets (including the group-membership ones above), interactive auth, and secret-shaped literals. Treat a manual review as equally mandatory in its absence, not optional because CI doesn't exist.
