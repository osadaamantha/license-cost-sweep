# license-cost-sweep
Finds wasted licence spend, including disabled accounts with paid licences, shared mailboxes with unnecessary licences, and licensed users that have never logged in.

## Development

This project uses Python 3.12+ and [uv](https://docs.astral.sh/uv/) for environments and dependency management.

```powershell
uv sync
uv run python --version
```

Use `develop` as the integration branch. Create work branches as `feature/<slug>`, `fix/<slug>`, `chore/<slug>`, or `docs/<slug>`, and merge through reviewed pull requests. Durable repository guidance is in `CLAUDE.md`; repository-scoped Claude Code skills are in `.claude/skills/`.
