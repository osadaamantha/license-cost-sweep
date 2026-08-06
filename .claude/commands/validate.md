---
description: Run the full local pre-PR validation gate for this repo, reporting any gate skipped due to missing tooling.
---

Run this repository's local pre-PR checks, in order, and report the outcome of each — including gates you had to skip because the required tool isn't installed or the target doesn't exist yet. Never report a skipped gate as passed.

1. `git diff --check` (repo root) — flag whitespace errors.
2. `uv lock --check` (repo root, while `pyproject.toml` exists).
3. If `infra/` exists and any file under it changed in this session's work: from `infra/`, run `az bicep build --file main.bicep` then `az bicep lint --file main.bicep`. If `az` or the `bicep` CLI isn't installed, report this gate as **skipped — az/bicep not installed** rather than passed; point at the `bootstrap-development-environment` skill. If `infra/` doesn't exist, report this gate as **not applicable — no infra yet**.
4. If any runtime/PowerShell/Exchange/Graph code changed: run `/safety-scan`.
5. There is no Pester suite in this repo yet. `PSScriptAnalyzerSettings.psd1` exists but there is no PowerShell code to analyse yet either — if `powershell-quality` work is in scope, note explicitly that these checks don't exist rather than silently omitting them.

Finish with a short pass/fail/skipped summary per gate.
