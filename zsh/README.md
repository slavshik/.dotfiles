# Zsh Modules

## Jira CLI (`jira.zsh`)

Multi-instance Jira client. Each company folder registers its profile.

### Setup

Company `index.zsh` calls `jira-register <label> <host> <pat_env_var> [auth_type]`.
PAT tokens stored in each company's `.secure.zsh` (git-ignored).

Requires: `curl`, `jq`, `fzf` (for `jira-status`).

### Commands

| Command | Description |
|---|---|
| `jira <KEY>` | View issue details |
| `jira-open <KEY>` | Open issue in browser |
| `jira-my [N]` | My unresolved issues (default 15) |
| `jira-search <text>` | Free-text search |
| `jira-comment <KEY> <msg>` | Add a comment |
| `jira-assign <KEY> [user]` | Assign issue (defaults to self) |
| `jira-status <KEY>` | Transition status via fzf picker |
| `jira-use [label]` | Switch Jira profile (or list all) |

Issue keys are auto-uppercased. Tab completion available after running `jira-my` once.

---

## GitLab CLI (`gitlab.zsh`)

MR and pipeline helpers using `glab` + `fzf`. Requires VPN for corporate instances.

### Setup

Set in company `.secure.zsh`:
```zsh
export GITLAB_TOKEN=glpat-...
export GITLAB_HOST=gitlab.example.com
```

Requires: `glab`, `fzf`.

### Commands

| Command | Description |
|---|---|
| `gl-mrs` | My open MRs → fzf → open in browser |
| `gl-mrs-all` | All open MRs → fzf → open in browser |
| `gl-mr <ID>` | View MR details in terminal |
| `gl-mr-open <ID>` | Open MR in browser |
| `gl-pipes` | Recent pipelines → fzf → view details |

All commands pass extra args to `glab`. Use `-R group/repo` to target a specific repo from any directory.
