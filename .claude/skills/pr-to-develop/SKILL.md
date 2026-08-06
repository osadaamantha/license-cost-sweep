---
name: pr-to-develop
description: Prepare, open, review, and merge a pull request into develop for this repository. Use after work on a published branch is ready for integration.
---

# PR to Develop

`gh` is authenticated (`gh auth status`). There is **no CI** on this repository — no `.github/workflows/`. Nothing runs automatically against the PR, so the local gates below are the only validation that happens before human review.

1. Confirm the current branch is a published `feature/`, `fix/`, `chore/`, or `docs/` branch and the target is `develop`.
2. Fetch `origin`. If `origin/develop` advanced, merge it into the work branch and push the merge commit; do not rebase a published branch.
3. Run the gates that actually exist, and report any that don't apply or can't run rather than skipping silently:
   - `uv lock --check` (while `pyproject.toml` exists)
   - `git diff --check`
   - if `infra/**` exists and changed: `az bicep build --file main.bicep` and `az bicep lint --file main.bicep` from `infra/` — report as skipped if `az`/`bicep` aren't installed, don't claim they ran
   - `/safety-scan` if any runtime/Exchange/Graph code changed
4. Review the full diff yourself for secrets, certificates, client data, generated files, and unintended changes — this substitutes for the CI review that doesn't exist here.
5. Create a pull request with base `develop`, a concise summary, validation evidence (including anything skipped and why), and no automatic branch deletion.
6. Require passing checks and an eligible approving review. Do not self-approve or bypass protection.
7. Squash-merge only after approval, then fast-forward local `develop` from `origin/develop`.

If GitHub protection cannot be inspected or changed, report the limitation and leave merging to an authorized reviewer.
