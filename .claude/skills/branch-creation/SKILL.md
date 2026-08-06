---
name: branch-creation
description: Safely create, name, synchronize, and publish Git branches for this repository. Use when starting feature, fix, chore, or documentation work, or when publishing a work branch.
---

# Branch Creation

`origin` is `https://github.com/MSP-Blueshift/license-cost-sweep.git`. `main` and `develop` both exist on the remote; ordinary work starts from `origin/develop`. See `CLAUDE.md` for the full branch policy — this skill is the procedure for acting on it.

1. Inspect `git status --short --branch`; preserve unrelated changes and never stash, commit, or discard them automatically.
2. Fetch `origin --prune` and use `origin/develop` as the base for normal work. Use `main` only for release or repository-administration work.
3. Choose exactly one lowercase hyphenated name: `feature/<slug>`, `fix/<slug>`, `chore/<slug>`, or `docs/<slug>`.
4. Create the branch from the remote base and publish it with an explicit upstream before editing tracked files:
   ```powershell
   git switch -c <type>/<slug> origin/develop
   git push -u origin <type>/<slug>
   ```
5. Report the branch name, base commit, upstream, and pre-existing working-tree changes.

A `PreToolUse` hook (`.claude/hooks/require-work-branch.ps1`) denies `Edit`/`Write`/`NotebookEdit` while the current branch is `main`, `develop`, or undetermined — file edits stay blocked until step 4 is done. This is enforcement, not just guidance.

Do not force-push, rewrite shared history, delete branches, or push directly to `main` or `develop`.
