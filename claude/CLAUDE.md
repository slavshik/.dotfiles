<!-- User-level CLAUDE.md: applies to every Claude Code session on this machine.
     Repo-level instructions for working inside the dotfiles repo itself live at ~/.dotfiles/CLAUDE.md. -->
# graphify
- **graphify** (`~/.claude/skills/graphify/SKILL.md`) - any input to knowledge graph. Trigger: `/graphify`
When the user types `/graphify`, invoke the Skill tool with `skill: "graphify"` before doing anything else.

# GitHub
- Use `gh-axi` for GitHub operations — issues, PRs, workflow runs, releases, labels, gists, secrets, and raw API (`gh-axi api`). Prefer it over `gh` and over the GitHub MCP: same data, roughly half the tokens, explicit empty states and structured errors.
- `gh-axi <command> --help` lists the flags; `gh-axi` alone prints a dashboard of the current repo. Truncated output always names an escape hatch (`--full`, `--fields`).
- Fall back to `gh` only where `gh-axi` has no equivalent (`gh auth`, `gh repo clone`, interactive flows).
