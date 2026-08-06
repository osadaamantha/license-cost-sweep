---
description: Build, lint, and run az deployment what-if for the Bicep infra, then stop and summarize — never proceeds to a real deployment.
---

**No `infra/` directory exists yet.** Confirm it exists before running this — if it doesn't, report that plainly rather than attempting the commands below.

From `infra/`, run in order and stop here — this command never runs `az deployment sub create`:

```powershell
az bicep build --file main.bicep
az bicep lint --file main.bicep
az deployment sub what-if --location australiaeast --template-file main.bicep --parameters main.prod.bicepparam
```

If `az` or the `bicep` CLI isn't installed, report that plainly (see `bootstrap-development-environment`) rather than skipping ahead.

Summarize the what-if output: what's being created, changed, or replaced, and flag anything unexpected — especially a `Replace` on Key Vault, Storage, or ACR (purge protection and global name uniqueness make those expensive to get wrong; see `bicep-authoring`). Deploying for real is a separate, explicitly-confirmed step handled by the `deploy-azure-container-job` skill, not this command.
