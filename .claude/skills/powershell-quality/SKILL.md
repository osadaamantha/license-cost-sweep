---
name: powershell-quality
description: Implement, review, or test production PowerShell 7 code for this project. Use for runtime modules, scripts, tests, CI checks, and PowerShell code-quality fixes.
---

# PowerShell Quality

**No PowerShell module exists in this repo yet.** The first production PS7 change establishes the layout — a module manifest (`.psd1`), `Public/`/`Private/` function folders, and a `tests/` directory for Pester — rather than assuming one is already there. The intended module name is `LicenseCostSweep`, with function noun prefix `Lic` (e.g. `Get-LicWasteReport`).

- Target PowerShell 7 and enable strict mode (`Set-StrictMode -Version Latest`) in production modules.
- Use approved verbs (`Get-Verb`), parameter validation, module boundaries, typed `PSCustomObject` records, and UTC timestamps.
- Keep business-rule functions pure and free of network calls; cover them with Pester fixtures.
- Apply timeouts, bounded retries, structured errors, and per-client failure isolation around network operations (Exchange Online, Graph, Storage, Key Vault).
- Run PSScriptAnalyzer and Pester before integration — both are installed on this workstation (PSScriptAnalyzer 1.22.0, Pester 5.6.1), but if a future environment is missing either, say so rather than reporting the check as passed. Fix warnings deliberately rather than suppressing them broadly.
- Keep credentials in Key Vault, never in parameters, source, logs, test fixtures, Docker layers, or report workbooks.

Do not use interactive authentication in the scheduled runtime. Flag uncertain API fields, permissions, and service limits rather than inventing them.
