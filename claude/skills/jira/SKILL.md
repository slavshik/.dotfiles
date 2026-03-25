---
name: jira
description: Read a Jira ticket and display its full details including description, acceptance criteria, and recent comments. Use when the user mentions a Jira key (e.g. ELA-123, PROJ-456), asks to look up a ticket, or wants context from a Jira issue.
tools: Bash, Read
---

# Jira Ticket Reader

Fetch and display full details of a Jira ticket.

## Input

The ticket key is either:
- Passed as an argument (e.g. `/jira ELA-123`)
- Mentioned by the user in conversation
- Inferred from git context when the user says "current ticket", "this ticket", "the jira issue", etc.

If no key is provided and it wasn't possible to infer one, ask the user.

## Inferring key from git context

Use `_jira_branch_key` from dotfiles — it extracts a Jira key from the current branch name:

```bash
key=$(zsh -i -c "_jira_branch_key" 2>/dev/null)
```

If the branch yields nothing, fall back to recent commit messages:

```bash
key=$(git log --oneline -10 2>/dev/null | grep -oE '[A-Z]+-[0-9]+' | head -1)
```

Inform the user which key was inferred before displaying the ticket.

## How to fetch

Use `_jira_fetch_full` from dotfiles via an interactive zsh shell (dotfiles are auto-loaded):

```bash
KEY="${KEY^^}"  # uppercase

res=$(zsh -i -c "_jira_fetch_full $KEY" 2>/dev/null)

# Check for errors
err=$(echo "$res" | jq -r '.errorMessages[0] // empty' 2>/dev/null)
if [[ -n "$err" ]]; then
  echo "Error: $err"; exit 1
fi
```

- `_jira_fetch_full KEY` — defined in `~/.dotfiles/zsh/jira.zsh`, fetches all fields: summary, status, assignee, priority, issuetype, description, labels, components, comment, attachment, fixVersions, story points, sprint
- `zsh -i` loads dotfiles automatically — no explicit sourcing needed in the skill

## Output format

Display the ticket in a clean, structured way:

```
ELA-123  [Story] Short summary title
─────────────────────────────────────────
Status:    In Progress
Priority:  Medium
Assignee:  John Doe
Labels:    frontend, urgent
Sprint:    Sprint 42
Story pts: 3

Description:
  <rendered description text, stripping Jira wiki markup where possible>

Acceptance Criteria:
  <extract from description if it contains "Acceptance Criteria" section>

Comments (last 3):
  [2026-03-20 Jane Doe] Comment text here...
  [2026-03-21 John Doe] Another comment...
```

## Processing tips

- Parse with `jq`. Description is in `.fields.description` (plain text string in API v2).
- Comments are in `.fields.comment.comments[]` — show the last 3.
- If description contains "Acceptance Criteria" or "AC:" section, call it out separately.
- Strip or simplify Jira wiki markup (`{code}`, `*bold*`, `h2.`, etc.) for readability.
- If a field is null/missing, skip it rather than showing "null".
- If the API returns an error (`errorMessages`), show it clearly and stop.

## Attachments

Attachments are in `.fields.attachment[]`. Each has:
- `.filename` — original file name
- `.mimeType` — e.g. `image/png`, `image/jpeg`, `application/pdf`
- `.content` — direct download URL (requires auth)
- `.thumbnail` — thumbnail URL for images

**To display image attachments:**

1. Filter for images (`mimeType` starts with `image/`):
```bash
images=$(echo "$res" | jq -r '.fields.attachment[] | select(.mimeType | startswith("image/")) | "\(.filename)\t\(.content)"')
```

2. For each image, download to a temp file and use the Read tool to display it:
```bash
tmpfile=$(mktemp /tmp/jira-attachment-XXXXXX.png)
zsh -i -c "_jira_curl '$content_url' -o '$tmpfile'" 2>/dev/null
# Then use Read tool on $tmpfile — Claude will render the image visually
rm -f "$tmpfile"
```

**Non-image attachments** (PDFs, ZIPs, etc.): just list filename and size — don't download.

**When to show attachments:**
- Always list attachment filenames at the end of the ticket output (if any exist)
- Download and display images only if the user asks, or if there are ≤3 images and the ticket has design/UI context

## Example jq snippets

```bash
echo "$res" | jq -r '
  "\(.key)  [\(.fields.issuetype.name)] \(.fields.summary)\n" +
  "Status:    \(.fields.status.name)\n" +
  "Priority:  \(.fields.priority.name)\n" +
  "Assignee:  \(.fields.assignee.displayName // "Unassigned")\n" +
  (if (.fields.labels | length) > 0 then "Labels:    \(.fields.labels | join(", "))\n" else "" end) +
  (if .fields.customfield_10016 != null then "Story pts: \(.fields.customfield_10016)\n" else "" end) +
  "\nDescription:\n\(.fields.description // "(none)")"
'
```

For comments:
```bash
echo "$res" | jq -r '
  .fields.comment.comments[-3:] |
  .[] |
  "[\(.updated[:10]) \(.author.displayName)] \(.body | split("\n")[0])"
'
```
