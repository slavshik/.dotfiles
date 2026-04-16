---
name: jira
description: Interact with Jira tickets — view details, add comments, assign, or transition status. Use when the user mentions a Jira key (e.g. ELA-123, PROJ-456), asks to look up a ticket, wants context from a Jira issue, or wants to comment/assign/update a ticket.
tools: Bash, Read
---

# Jira Ticket Helper

View, comment on, assign, unassign, transition, and search Jira tickets.

## Execution flow

1. Resolve ticket key.
2. Resolve intent (view vs mutate).
3. Run the matching helper command.
4. Render concise, structured output.

Use `zsh -i -c '...'` for all Jira helpers so dotfiles and auth are loaded automatically.
All helpers auto-uppercase keys.

`jira-status` (fzf) is interactive-only and should not be used from the Bash tool.

## Key resolution

Key sources, in order:
- Explicit argument (for example `/jira ELA-123`)
- Jira key mentioned in conversation
- Git context inference when user says "current ticket", "this ticket", etc.

Inference commands:

```bash
key=$(zsh -i -c "_jira_branch_key" 2>/dev/null)
[[ -z "$key" ]] && key=$(git log --oneline -10 2>/dev/null | grep -oE '[A-Z]+-[0-9]+' | head -1)
```

If still empty, ask the user for the key.
If inferred, state which key was inferred before using it.
For mutating actions on inferred keys (comment/assign/unassign/transition), explicitly state the inferred key before executing.

## Intent → command map

- Default view: `jira KEY` (quick summary)
- Full detail view: `jira-detail KEY`
- Raw JSON (for parsing): `_jira_fetch_full KEY`
- Add comment: `jira-comment KEY MESSAGE`
- Assign: `jira-assign KEY [username]` (no username = assign to self)
- Unassign: `jira-unassign KEY`
- Transition: `jira-transition KEY "target status"` (fuzzy status match)
- My unresolved issues: `jira-my [limit]` (default 15)
- Free-text search: `jira-search "text"`
- My issues by status: `jira-by-status "In Progress"`
- Raw JQL: `jira-jql "JQL..." [maxResults]` (default 20)
- Find GitLab MR by ticket: `jira-mr KEY [--web]`
- Batch transition my issues: `jira-batch-transition "From" "To"`

## Retrieve and render

Quick view:

```bash
zsh -i -c 'jira KEY' 2>/dev/null
```

Full detail:

```bash
zsh -i -c 'jira-detail KEY' 2>/dev/null
```

Raw JSON + error handling:

```bash
res=$(zsh -i -c '_jira_fetch_full KEY' 2>/dev/null)
err=$(echo "$res" | jq -r '.errorMessages[0] // empty' 2>/dev/null)
[[ -n "$err" ]] && { echo "Error: $err"; exit 1; }
```

Render rules:
- Show header: `KEY [IssueType] Summary`
- Show key fields when present: status, priority, assignee, labels, sprint, story points
- Description: parse from `.fields.description`; simplify Jira wiki markup for readability
- If description includes "Acceptance Criteria" or "AC:", show that section separately
- Comments: show last 3 from `.fields.comment.comments[]`
- Skip missing/null fields; never print `null`

## Attachments policy

Attachments live at `.fields.attachment[]` (`filename`, `mimeType`, `content`, `thumbnail`).

- Always list attachment filenames at the end if any exist.
- Download and render images only when:
  - the user explicitly asks, or
  - there are at most 3 images and ticket context is clearly UI/design-focused.
- Non-image files (PDF/ZIP/etc.): list only, do not download by default.

Image extraction example:

```bash
echo "$res" | jq -r '.fields.attachment[]? | select(.mimeType | startswith("image/")) | "\(.filename)\t\(.content)"'
```
