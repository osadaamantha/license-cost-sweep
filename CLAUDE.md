# license-cost-sweep

Canonical project name is **`license-cost-sweep`** / intended PowerShell module **`LicenseCostSweep`** / function noun prefix **`Lic`** / Azure resource prefix **`liccost`** — American spelling throughout, matching the GitHub repo (`MSP-Blueshift/license-cost-sweep`).

## What this is

A multi-tenant MSP licence-waste audit. The intended shape mirrors the sibling `mailbox-audit-sweep` repo: one Entra app registration, authenticated with a certificate credential, consented into each client tenant via GDAP/Lighthouse. Read-only against Microsoft Graph and Exchange Online. It is meant to find, per client tenant:

1. Disabled/blocked accounts that still hold paid licences.
2. Shared mailboxes carrying licences they don't need (accounting for the legitimate exceptions: >50 GB mailbox size, litigation hold, in-place archive).
3. Licensed users who have never signed in.

Reports would land as Excel workbooks in blob storage, on a daily schedule — none of this is built yet (see below).

## Current state — read this before trusting any skill's assumptions

Concretely, as of this bootstrap commit:

- **Runtime code**: none. No `runtime/` directory, no PowerShell module, no functions.
- **Tests**: none. No `tests/` directory, no Pester suite.
- **CI**: none. No `.github/workflows/`. All gates are local/manual; `/validate` and `/safety-scan` in `.claude/commands/` are the closest substitute.
- **Infrastructure**: none. No `infra/`, no Bicep, no resource group, no Key Vault, no storage account. The `bicep-authoring`, `deploy-azure-container-job`, `container-image-release`, and `report-and-state-idempotency` skills describe the *intended* pattern (borrowed from the sibling repo) for when this work starts — they name planned resources (`caj-liccost-daily`, `kv-liccost-prod`, `stliccostprod`) that do not exist yet.
- **Container image**: none. No Dockerfile.
- **Python**: a vestigial `uv init --package` stub (`src/license_cost_sweep/__init__.py`, prints a greeting). Not the deliverable — kept alive only because `uv lock --check` is a live pre-PR gate.
- **Deployment topology**: undecided whether this shares the sibling's Entra app registration / GDAP consent / Key Vault / storage account, or gets its own. Don't assume either way — raise it when infra work starts.
- **Licence price source**: undecided. Microsoft Graph returns SKU and assignment data but never pricing — the cost basis will need to come from a CSP/Partner Center price list, a manually maintained CSV, or ITGlue. Flag this as an open dependency in any work that touches cost figures; don't invent a number or a source.
- **Entra ID P1/P2 coverage**: unknown per client tenant. The "never signed in" finding depends on `signInActivity`, which requires Entra ID P1/P2 in that tenant. Where it's absent, that finding must degrade to `Unknown` for that tenant, not be silently omitted or asserted anyway.

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

- The production runtime is **read-only** against Exchange Online, Microsoft Graph, and Entra ID. Never add `Set-`, `New-`, `Remove-`, `Enable-`, `Disable-`, or `Update-` mutation cmdlets to runtime code. This explicitly includes `Set-MgUserLicense`, `Set-MsolUserLicense`, `Set-AzureADUserLicense`, `Update-MgUser`, and `Set-Mailbox` — and, less obviously, `Remove-MgGroupMemberByRef`/`Remove-MgUserMemberOf`, because removing a group member revokes any licence assigned through that group. Onboarding/admin scripts that legitimately need mutation stay clearly separated from the runtime image.
- Secrets come only from Key Vault via the job's managed identity. Never write tokens, private keys, credentials, mailbox contents, subjects, licence cost figures, or client spreadsheets into source, logs, fixtures, test data, or prompts.
- Every client tenant is isolated: authenticate independently, use tenant-specific config, continue past a single client's failure, and never combine report or ticket data across clients.
- Missing or unavailable evidence — including sign-in activity where a tenant lacks Entra ID P1/P2, and licence pricing, which Graph never provides — is classified `Unknown`, never inferred into a finding.
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
