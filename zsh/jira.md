# Jira CLI (multi-instance)

Shell commands for multiple Jira instances. Switched via `jira-use`.

## Setup

1. Each company's `.secure.zsh` exports a PAT variable (e.g. `EVO_JIRA_PAT`, `ELA_JIRA_PAT`).
2. Profiles are registered in `zshrc` via `jira-register <label> <host> <pat_env_var> [auth_type]`.
3. `_jira_restore_profile` auto-restores the last-used profile on shell startup.

Requires: `curl`, `jq`, `fzf` (for `jira-status`).

## Profiles

| Label | Host | PAT variable |
|---|---|---|
| `evo` | `jira.evolution.com` | `EVO_JIRA_PAT` |
| `ela` | `jira.gosystem.io` | `ELA_JIRA_PAT` |

## Commands

| Command | Description |
|---|---|
| `jira-use [label]` | Switch profile (no args = show current) |
| `jira <KEY>` | View issue details |
| `jira-open <KEY>` | Open issue in browser |
| `jira-my [N]` | My unresolved issues (default 15) |
| `jira-search <text>` | Free-text search |
| `jira-comment <KEY> <msg>` | Add a comment |
| `jira-assign <KEY> [user]` | Assign issue (defaults to self) |
| `jira-status <KEY>` | Transition status via fzf picker |

Issue keys are auto-uppercased (`mondice-91` → `MONDICE-91`).

## Tab completion

- `jira-use <TAB>` — lists registered profiles
- `jira <TAB>` (and other KEY commands) — from per-profile cache + git branch
- Run `jira-my` once to populate the cache

## Internals

- Active profile persisted to `~/.local/state/jira-profile`
- Per-profile issue cache at `~/.cache/jira-issues-<label>`
- Auth uses indirect expansion `${(P)_JIRA_PAT_VAR}` — supports bearer/basic
