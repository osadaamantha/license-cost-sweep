---
name: container-image-release
description: Build, tag, and publish the license-cost-sweep runtime container image, and update the deployed job to reference it. Use when the runtime image doesn't exist yet, needs a Dockerfile, or needs a new release.
---

# Container Image Release

**No Dockerfile, build pipeline, or deployed job exists yet.** This skill describes the intended release pattern, mirrored from the sibling mailbox-audit-sweep repo, for establishing the image and every release after — confirm what actually exists before assuming any step here applies.

## Establishing the image (first time)

- Base on a PowerShell 7 image (e.g. `mcr.microsoft.com/powershell:7-...`) sized to the actual runtime — size the job's CPU/memory request to what the runtime genuinely needs rather than copying the sibling's figures unverified.
- Install only the modules the runtime needs (`ExchangeOnlineManagement`, `Microsoft.Graph.Authentication`, `Az.Accounts` as applicable) at build time, not at container start — a scheduled job with a bounded `replicaTimeout` shouldn't spend part of that budget on module installation.
- No interactive steps in the image or entrypoint — the job authenticates via managed identity and Key Vault, never a login prompt (see `graph-exchange-readonly`).

## Tagging and publishing every release

- **Always tag by immutable Git commit SHA. Never build or deploy `latest`** — treat this as a hard requirement to document in `infra/README.md` once that exists, not a style preference.
  ```powershell
  $sha = git rev-parse --short HEAD
  az acr build --registry <acr-name> --image "license-cost-sweep:$sha" --file <path-to-Dockerfile> .
  ```
- If the ACR admin user is disabled (`adminUserEnabled: false`, matching the sibling's convention), authentication for build/push is Entra-based through `az acr build`, not an ACR admin username/password. Don't re-enable the admin user to work around this.
- Confirm the pushed tag exists before referencing it: `az acr repository show-tags --name <acr-name> --repository license-cost-sweep`.

## Updating the deployed job to use a new image

- Update the image reference **through Bicep** (`main.bicep`'s image parameter, redeployed via `deploy-azure-container-job`) — never `az containerapp job update --image ...` directly, which would drift the running resource away from what the template describes and get silently reverted or conflict on the next `what-if`.
- After updating, the deploy skill's what-if step is what actually confirms the change before it goes live.

## Rollback

Roll back by redeploying a previous known-good SHA tag through the same Bicep path used to deploy forward — the SHA tag is what makes this possible, so never overwrite or delete a previously-deployed tag.
