---
name: jira
description: Interact with Jira tickets — view details, add comments, assign, or transition status. Use when the user mentions a Jira key (e.g. ELA-123, PROJ-456), asks to look up a ticket, wants context from a Jira issue, or wants to comment/assign/update a ticket.
tools: Bash, Read
---

# Jira Ticket Helper

View, comment on, assign, and transition Jira tickets.

## Input

The ticket key is either:
- Passed as an argument (e.g. `/jira ELA-123`)
- Mentioned by the user in conversation
- Inferred from git context when the user says "current ticket", "this ticket", "the jira issue", etc.

If no key is provided and it wasn't possible to infer one, ask the user.

**Actions** can be requested via arguments or natural language:
- `--comment "message"` or user says "add a comment" → use `jira-comment`
- `--assign [user]` or user says "assign to me" → use `jira-assign`
- User says "move to In Progress" / "transition" → use status transition API
- No action flag → default to fetching and displaying the ticket

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

**Quick view** (summary only):
```bash
zsh -i -c 'jira MONDICE-385' 2>/dev/null
```

**Full detail** (description, comments, attachments):
```bash
zsh -i -c 'jira-detail MONDICE-385' 2>/dev/null
```

**Raw JSON** (when you need to parse specific fields with jq):
```bash
res=$(zsh -i -c '_jira_fetch_full MONDICE-385' 2>/dev/null)
err=$(echo "$res" | jq -r '.errorMessages[0] // empty' 2>/dev/null)
[[ -n "$err" ]] && { echo "Error: $err"; exit 1; }
```

- `_jira_fetch_full KEY` — returns raw JSON with all fields: summary, status, assignee, priority, issuetype, description, labels, components, comment, attachment, fixVersions, story points, sprint
- `zsh -i` loads dotfiles automatically — no explicit sourcing needed
- Keys are auto-uppercased by all helpers

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

## Actions

The following dotfile helpers are available for mutating tickets. All use `zsh -i -c '...'` to auto-load dotfiles.

### Add a comment

```bash
zsh -i -c 'jira-comment MONDICE-385 Landscape now fixed, MR updated.' 2>/dev/null
```

- `jira-comment <KEY> <message>` — adds a comment to the ticket
- Output: `Comment added (id: 12345)`

### Assign a ticket

```bash
zsh -i -c 'jira-assign MONDICE-385' 2>/dev/null        # assign to self
zsh -i -c 'jira-assign MONDICE-385 jdoe' 2>/dev/null   # assign to specific user
```

- `jira-assign <KEY> [username]` — assigns the ticket (defaults to self if no user given)

### Transition status

```bash
zsh -i -c 'jira-transition MONDICE-385 "in progress"' 2>/dev/null
```

- `jira-transition <KEY> <status>` — fuzzy-matches the target status name against available transitions
- Output: `MONDICE-385 → In Progress`
- Note: `jira-status` (fzf picker) is interactive-only and won't work in Bash tool

### Search and list

```bash
zsh -i -c 'jira-my' 2>/dev/null              # my unresolved issues (default 15)
zsh -i -c 'jira-my 30' 2>/dev/null            # up to 30 results
zsh -i -c 'jira-search "drag and drop"' 2>/dev/null  # free-text search
zsh -i -c 'jira-by-status "In Progress"' 2>/dev/null # my issues filtered by status
```

### Raw JQL query

```bash
zsh -i -c 'jira-jql "project = OPQA AND reporter = currentUser() ORDER BY created DESC" 20' 2>/dev/null
```

- `jira-jql <JQL> [maxResults]` — runs an arbitrary JQL query (default 20 results)
- Use this when built-in commands (`jira-my`, `jira-search`, `jira-by-status`) are not flexible enough
- Common JQL examples:
  - `project = PROJ AND reporter = currentUser()` — tickets created by me
  - `project = PROJ AND status = "In Progress" AND assignee = currentUser()` — my in-progress work
  - `project = PROJ AND created >= -7d` — tickets created in the last week
  - `labels = frontend AND resolution = Unresolved` — open frontend tickets

### Find GitLab MR by ticket

```bash
zsh -i -c 'jira-mr MONDICE-385' 2>/dev/null         # find MR
zsh -i -c 'jira-mr MONDICE-385 --web' 2>/dev/null   # find and open in browser
```

### Batch transition

```bash
zsh -i -c 'jira-batch-transition "To Do" "In Progress"' 2>/dev/null
```

- Moves all of the user's issues from one status to another
