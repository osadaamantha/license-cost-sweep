---
name: deploy-azure-container-job
description: Validate, deploy, operate, or roll back the license-cost-sweep Azure Container Apps Job infrastructure. Use for what-if review, deployment, manual job execution, and rollback of infra/. For writing or changing Bicep modules themselves, use bicep-authoring; for building and tagging the runtime image, use container-image-release.
---

# Deploy Azure Container Job

**No infrastructure is deployed yet.** This skill describes the intended deployment pattern, mirrored from the sibling mailbox-audit-sweep repo, for when `infra/` and a real image exist — confirm both before assuming any command here can actually run.

This deployment is planned to be **subscription-scoped**, not resource-group-scoped — `main.bicep` would create the resource group itself. Run every command from `infra/`.

1. Require Azure CLI authentication (`az account show`) and explicitly identify the subscription, and confirm `main.prod.bicepparam` is the intended parameter file (region `australiaeast`, planned RG `rg-license-cost-sweep-prod`).
2. Validate and review before any deployment:
   ```powershell
   az bicep build --file main.bicep
   az bicep lint --file main.bicep
   az deployment sub what-if --location australiaeast --template-file main.bicep --parameters main.prod.bicepparam
   ```
   Treat a non-empty what-if as a change-review gate — read it, don't skim it.
3. Require explicit confirmation before running `az deployment sub create` or any destructive resource replacement:
   ```powershell
   az deployment sub create --location australiaeast --template-file main.bicep --parameters main.prod.bicepparam
   ```
4. Known operational traps, once this deployment exists (carried over from the sibling repo's experience — verify each still applies as this infra is actually built):
   - **Key Vault purge protection is on** (`enablePurgeProtection: true`). A failed deploy is not cleanly re-runnable under the same vault name for 90 days — don't treat vault deletion as a quick fix.
   - **Key Vault, Storage Account, and ACR names must be globally unique** across Azure. A name-conflict error means changing the suffix in `main.prod.bicepparam` and redeploying, not retrying the same name.
   - **`allowSharedKeyAccess: false`** on the storage account, if configured the same way — every `az storage blob` command against it needs `--auth-mode login`; account keys and connection strings will not work.
   - The job (planned name `caj-liccost-daily`) would run a placeholder image (`mcr.microsoft.com/k8se/quickstart:latest`) until a real one exists — deploying infra changes does not require a real image yet.
5. Never deploy `latest` as the real runtime image tag — always an immutable Git commit SHA (see `container-image-release`).
6. Start manual executions only when requested:
   ```powershell
   az containerapp job start --name caj-liccost-daily --resource-group rg-license-cost-sweep-prod
   az containerapp job execution list --name caj-liccost-daily --resource-group rg-license-cost-sweep-prod
   ```
   Inspect execution status and Log Analytics output; keep secrets out of anything you print.
7. Roll back by redeploying a known-good immutable image tag and validated parameter set through the same Bicep path — never delete resources as a rollback shortcut (and purge protection would block a clean vault delete anyway).

Do not use this skill for local validation or workstation setup (see `bootstrap-development-environment`) or for authoring/changing the Bicep modules themselves (see `bicep-authoring`).
