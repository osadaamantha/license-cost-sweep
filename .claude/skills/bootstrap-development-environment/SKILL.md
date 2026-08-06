---
name: bootstrap-development-environment
description: Set up and verify the Windows development toolchain for this repository. Use when installing or repairing Azure CLI, PowerShell 7, Git, GitHub CLI, uv, Bicep, or Container Apps tooling.
---

# Bootstrap Development Environment

Use WinGet for workstation packages. Detect current versions first and install only missing or outdated tools.

Verified present on this workstation: `git`, `pwsh` 7.6.4, `gh` 2.96.0 (authenticated), `uv` 0.12.0, `az` 2.89.0 (`containerapp` extension), `bicep` 0.46.1, `PSScriptAnalyzer` 1.22.0, `Pester` 5.6.1. `python` is not on PATH directly — use `uv run python`; `cpython-3.12.13` is already installed under uv's own Python store. Verified **absent**: Docker, WSL2. Re-verify rather than trusting this list blindly — it will drift.

1. Verify `git`, `pwsh`, `az`, `gh`, `uv`, Docker, and Python availability; report every version. Also check PowerShell module availability:
   ```powershell
   Get-Module -ListAvailable -Name Pester, PSScriptAnalyzer, ExchangeOnlineManagement, Microsoft.Graph.Authentication, Az.Accounts
   ```
2. Install or update Azure CLI, PowerShell 7, GitHub CLI, and uv through trusted package sources (WinGet).
3. Install PSScriptAnalyzer and Pester 5.x (`Install-Module -Name Pester -MinimumVersion 5.0 -Scope CurrentUser -SkipPublisherCheck` — an older Pester may already be loaded from the system path, so don't assume `Install-Module` alone makes v5 the active version; check `Get-Module -ListAvailable Pester` afterward).
4. Ensure the existing Git installation is available on PATH in a new terminal session.
5. Once `infra/` exists: use `az bicep install` and install or update the `containerapp` Azure CLI extension (`az extension add --name containerapp` / `az extension update --name containerapp`). Not needed before then.
6. Do not install Docker Desktop automatically; report its status and prerequisites instead.
7. Use interactive Azure login only when requested. Display the selected subscription, tenant, and account without creating or changing Azure resources.

Never log access tokens, secrets, tenant credentials, or certificate material.
