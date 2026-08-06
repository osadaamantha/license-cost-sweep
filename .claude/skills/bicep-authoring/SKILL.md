---
name: bicep-authoring
description: Write or change Bicep modules under infra/. Use for adding resources, changing module parameters/outputs, or reviewing infra pull requests. For deploying, running what-if, or operating the deployed job, use deploy-azure-container-job.
---

# Bicep Authoring

**No `infra/` directory exists yet.** This skill sets the pattern for the first infra pass, mirrored from the sibling mailbox-audit-sweep repo's established conventions, rather than describing something already in place. Confirm `infra/` exists before assuming any of the structure below is present.

## Module conventions to establish

- `main.bicep` as the subscription-scoped entry point: creates the resource group, owns all defaults (cron schedule, resource names, placeholder image tag), and declares the deployment's outputs. Keep defaults here, visible in one place, rather than pushed down into leaf modules.
- `infra/modules/resources.bicep` as the resource-group-scoped orchestrator, wiring leaf modules together with **explicit `dependsOn`** ordering (identity + Log Analytics + Key Vault + storage + ACR → environment → RBAC → job). Any new resource that other resources depend on needs an explicit dependency here — don't rely on implicit ordering from parameter references alone if the dependency isn't expressed through them.
- One leaf module per resource under `infra/modules/` (`managedIdentity.bicep`, `keyVault.bicep`, `storageAccount.bicep`, etc.) rather than inlining resources into `resources.bicep`.
- Pass values **down as params, and back up as outputs** — don't re-read a resource's properties with ARM-style `reference()` when the value is already available as an output from a module already deployed.
- Inline `listKeys()` calls (e.g. reading a Log Analytics shared key to pass to a Container Apps environment) are an accepted way to pass a workspace key — not a secret leak, provided it's never surfaced as a Bicep `output`.

## Validate before proposing a change

```powershell
cd infra
az bicep build --file main.bicep
az bicep lint --file main.bicep
```
Both require `az`/`bicep` to be installed — if they aren't (`bootstrap-development-environment` fixes this), say so rather than skipping validation silently.

## Reading a what-if diff

`az deployment sub what-if --location australiaeast --template-file main.bicep --parameters main.prod.bicepparam` (planned resource group name `rg-license-cost-sweep-prod`) is how a proposed change gets reviewed before deployment (see `deploy-azure-container-job` for running it). When authoring, predict what the what-if should show — an unexpected `Delete` or `Replace` on Key Vault/Storage/ACR is a signal you changed something that forces resource recreation, which interacts badly with:

- **Key Vault purge protection** (`enablePurgeProtection: true`) — a forced Key Vault replacement can't be cleanly undone for 90 days.
- **Globally unique names** on Key Vault, Storage, and ACR — changing a name parameter always shows as a replace, not an update, because Azure treats it as a new resource.

## Networking posture

Follow the sibling's documented scope cut unless this project's threat model requires otherwise: Storage, Key Vault, and ACR on `networkAcls.defaultAction: 'Deny'` with `bypass: 'AzureServices'`, not private endpoints/VNet. Adding private networking is a substantial follow-up (VNet, subnets, private endpoints, private DNS zones) that should be its own change, not something folded into an unrelated task.

## RBAC

Grant the minimum built-in role for the job's need, by role-definition GUID, `principalType: 'ServicePrincipal'`, scoped as narrowly as the resource allows (Key Vault Secrets User, Storage Blob Data Contributor, AcrPull). Don't grant Owner/Contributor as a shortcut.
