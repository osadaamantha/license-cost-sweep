# license-cost-sweep

Canonical project name is **`license-cost-sweep`** / intended PowerShell module **`LicenseCostSweep`** / function noun prefix **`Lic`** / Azure resource prefix **`liccost`** — American spelling throughout, matching the GitHub repo (`MSP-Blueshift/license-cost-sweep`).

## What this is

A multi-tenant MSP licence-waste audit. Read-only against Microsoft Graph and Exchange Online. Despite the name, **no cost/pricing calculation is in scope for v1** — confirmed directly with the client-facing stakeholder ("What pricing should we use: CSP cost, Microsoft list price, or a provided cost list?" → "This is not needed"). The "sweep" here identifies waste and risk patterns, not dollar values; don't build a CSP-cost or Microsoft-list-price lookup.

**Auth model — open question, don't assume.** The sibling `mailbox-audit-sweep` repo originally assumed a standalone cert-based Entra app + GDAP/Lighthouse consent, then discovered mid-project that the real, confirmed design is a **shared** multi-tenant app (`MSP Blueshift Integration`) used across every MSP automation, authenticating via a federated identity credential tied to a managed identity — no certificate, no per-project app registration. That shared app's documented permission set already includes licence-usage reporting scopes. Before designing this project's auth, confirm with the stakeholder whether license-cost-sweep should reuse that same shared app/identity rather than provisioning a new one. Don't build against either assumption until it's confirmed.

It is meant to find, per client tenant:

1. **Disabled/blocked accounts that still hold paid licences.**
2. **Duplicate/overlapping licences** — a user holding two SKUs where one makes the other redundant. Confirmed in-scope ("this would help if a certain licence is not needed"), but the actual overlap map (which SKU pairs count as redundant) is **not yet defined** — flag this explicitly as an open dependency in any work that touches this finding; don't invent a plausible-looking overlap table.
3. **Licensed users who have never signed in** — 30-day inactivity threshold. New users get the same 30-day grace period before being flagged as "never signed in," measured from account creation date.
4. **Shared mailboxes carrying paid licences** — flagged for **manual review, never auto-classified as waste or auto-exempted**. The stakeholder was explicit this is context-dependent ("some mailboxes are signed into as a way to create a mail merge") — there is no confirmed size/litigation-hold/archive exception rule. Report these as a distinct "needs review" category, not a finding with a verdict.
5. **Service/automation accounts** are reported **separately** from regular user findings, not excluded from the report and not folded into another category.

**Explicitly not a separate category**: accounts on long-term leave or legal hold get no bespoke exclusion list — they fold into the standard inactive-user detection (#3), per the stakeholder's own answer.

**Scope is all paid licences** — no subset filtering, and group-assigned licences are not shown separately from directly-assigned ones (the "all licences" scope already covers them; don't build a direct-vs-group-assigned split into the report).

**Ticketing**: one Autotask ticket per client tenant, listing every finding in that single ticket — never one ticket per individual finding. This is the one intentional mutation this runtime performs (see the safety rules below) — everything else stays read-only.

Reports would land as Excel workbooks in blob storage, on a daily/weekly schedule (cadence not yet decided) — none of this is built yet (see below).

## Current state — read this before trusting any skill's assumptions

Concretely, as of this bootstrap commit:

- **Runtime code**: none. No `runtime/` directory, no PowerShell module, no functions.
- **Tests**: none. No `tests/` directory, no Pester suite.
- **CI**: none. No `.github/workflows/`. All gates are local/manual; `/validate` and `/safety-scan` in `.claude/commands/` are the closest substitute.
- **Infrastructure**: none. No `infra/`, no Bicep, no resource group, no Key Vault, no storage account. The `bicep-authoring`, `deploy-azure-container-job`, `container-image-release`, and `report-and-state-idempotency` skills describe the *intended* pattern (borrowed from the sibling repo) for when this work starts — they name planned resources (`caj-liccost-daily`, `kv-liccost-prod`, `stliccostprod`) that do not exist yet.
- **Container image**: none. No Dockerfile.
- **Python**: a vestigial `uv init --package` stub (`src/license_cost_sweep/__init__.py`, prints a greeting). Not the deliverable — kept alive only because `uv lock --check` is a live pre-PR gate.
- **Deployment topology**: undecided whether this shares the sibling's Key Vault / storage account / Container Apps Environment, or gets its own. See the auth-model open question above — raise both together when infra work starts.
- **Licence pricing**: confirmed **out of scope for v1** (see "What this is" above) — this is a settled decision, not an open dependency to chase down. Don't build a cost-basis lookup against a CSP price list, CSV, or ITGlue unless a later, explicit scope change asks for it.
- **Duplicate/overlapping licence SKU map**: undecided — confirmed in-scope as a finding, but which specific SKU pairs count as "redundant" has not been defined yet. Flag this as an open dependency in any Analysis-layer work that touches this finding; don't invent a plausible-looking overlap table.
- **Entra ID P1/P2 coverage**: unknown per client tenant. The "never signed in" finding depends on `signInActivity`, which requires Entra ID P1/P2 in that tenant. Where it's absent, that finding must degrade to `Unknown` for that tenant, not be silently omitted or asserted anyway.
- **Autotask ticket-creation credentials/board**: not yet arranged. The confirmed ticketing shape (one ticket per client, all findings listed) is settled; the actual API key and target board are not.

Don't let a skill or a habit from other repos assume tooling, tests, or CI that don't exist here. State the gap instead of working around it silently.

## Environment reality on this workstation

Verified present: `git`, `pwsh` 7.6.4, `gh` 2.96.0 (authenticated as `anuk-msp`), `uv` 0.12.0, `az` 2.89.0 (`containerapp` extension), `bicep` 0.46.1, `PSScriptAnalyzer` 1.22.0, `Pester` 5.6.1. `python` is not on PATH directly — use `uv run python`; `cpython-3.12.13` is already installed under uv's Python store, so no fresh download is needed.
Verified **absent**: Docker, WSL2.

This workstation runs **ThreatLocker** (app-control, `defaultdeny`+`ringfencing` enforced). A newly installed binary or DLL that hasn't been executed yet under an active learning-mode maintenance window will be blocked with a "Request Access" popup — this is not a broken install, and not Defender. If a command fails with an access-denied-shaped error and the tool is confirmed installed, suspect ThreatLocker before assuming the install failed; ask the user to check for a learning window or grant Request Access for that specific binary.

`az login` has not been run on this workstation — commands needing an authenticated context (`az deployment sub what-if`, etc.) will fail until that happens; this is expected, not a tooling gap, and moot until `infra/` exists anyway.

## Branch policy — always in effect

- `main` = release branch. `develop` = shared integration branch. Never edit, commit, or push directly to either.
- Start every change on `feature/<slug>`, `fix/<slug>`, `chore/<slug>`, or `docs/<slug>`, branched from `origin/develop` (lowercase, hyphenated slug).
- Merge into `develop` only through a reviewed pull request. No CI runs on that PR — review is entirely human, so get the local gates right before opening it.
- If `origin/develop` advances after you've published a branch, merge it in — never rebase or force-push a published branch.
- A `PreToolUse` hook (`.claude/hooks/require-work-branch.ps1`) denies file edits on `main`/`develop`; another (`.claude/hooks/guard-protected-git.ps1`) denies pushes to those branches and any force-push. Both fire regardless of skill — you don't need to remember this manually, but don't try to route around it either.
- Both `main` and `develop` have GitHub branch protection (1 required approving review, `enforce_admins: true`, no force-push, no deletion) — merging your own PR is not possible even as an admin.

## Non-negotiable safety rules

- The production runtime is **read-only** against Exchange Online, Microsoft Graph, and Entra ID. Never add `Set-`, `New-`, `Remove-`, `Enable-`, `Disable-`, or `Update-` mutation cmdlets to runtime code. This explicitly includes `Set-MgUserLicense`, `Set-MsolUserLicense`, `Set-AzureADUserLicense`, `Update-MgUser`, and `Set-Mailbox` — and, less obviously, `Remove-MgGroupMemberByRef`/`Remove-MgUserMemberOf`, because removing a group member revokes any licence assigned through that group. Onboarding/admin scripts that legitimately need mutation stay clearly separated from the runtime image. **One confirmed exception**: this runtime does create Autotask tickets (one per client, listing every finding) — that's an intended side effect, not a violation of the read-only rule. Keep ticket-creation code isolated in its own adapter; it should be the only mutating call path anywhere in the runtime.
- Secrets come only from Key Vault via the job's managed identity. Never write tokens, private keys, credentials, mailbox contents, subjects, or client spreadsheets into source, logs, fixtures, test data, or prompts.
- Every client tenant is isolated: authenticate independently, use tenant-specific config, continue past a single client's failure, and never combine report or ticket data across clients.
- Missing or unavailable evidence — including sign-in activity where a tenant lacks Entra ID P1/P2 — is classified `Unknown`, never inferred into a finding. (Licence pricing isn't in this category — it's confirmed out of scope for v1 entirely, not evidence this runtime attempts to collect.)
- Flag uncertain API fields, permissions, or service limits rather than inventing plausible-sounding ones.

## Commands that actually work today

```powershell
uv sync
uv run python --version
uv lock --check          # pre-PR gate
git diff --check          # pre-PR gate
```

Everything else — Pester, PSScriptAnalyzer, `az bicep`, `az deployment sub what-if` — has no target to run against yet (no PowerShell module, no `infra/`). The skills that reference them describe the intended pattern for when that work starts, not something runnable now.

## Repo map

- `.claude/` — this harness: skills, hooks, settings, commands.
- `src/license_cost_sweep/` — vestigial uv/Python stub, not the runtime.
- `pyproject.toml` / `uv.lock` / `.python-version` — exist solely to keep `uv lock --check` alive as a pre-PR gate.
- `runtime/`, `tests/`, `infra/` — do not exist yet; will appear as that work lands. Don't assume their structure without checking first.
- Never glob, read, or list `.venv/` — it's gitignored and can be large.

## Repository skills

Use the matching skill under `.claude/skills/` for branch creation, PR preparation, environment bootstrap, Azure deployment, Bicep authoring, container image release, PowerShell quality, licence-cost safety, report/state idempotency, and Graph/Exchange read-only access. They encode procedure; this file encodes policy that applies regardless of which skill is active.
