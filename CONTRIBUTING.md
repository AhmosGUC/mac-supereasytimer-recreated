# Contributing

- Branch naming: `issue-<N>-slug`. One issue per PR.
- Run `make test` and `make previews` before opening a PR.
- Follow [`docs/CLEAN_ROOM.md`](docs/CLEAN_ROOM.md) — it is mandatory.
- Update `CHANGELOG.md` under "Unreleased".

## Project skills for AI agents

Claude Code loads these from `.claude/skills/` automatically. Run one by name, e.g. `/clean-room-check`.

| Skill | Use it |
|---|---|
| `clean-room-check` | Before every PR, and whenever you add an asset, a dependency or a copied snippet |
| `ui-evidence` | For any UI change: render preview PNGs in CI, embed them in the PR, add owner test steps |
| `project-status` | To report progress, next steps and what's blocked on the owner |
