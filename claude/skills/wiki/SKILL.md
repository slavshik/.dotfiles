---
name: wiki
description: Fetch and search Confluence wiki pages. Trigger when a Confluence URL/page ID appears (including Jira output) or when the user asks to find/summarize wiki content.
tools: Bash, Read
---

# Confluence Wiki Helper

Read and search Confluence pages.

Use `zsh -i -c '...'` for all wiki helpers so dotfiles and `EVO_WIKI_PAT` auth are loaded automatically.

## Trigger

Load this skill when any of these appear:
- Confluence URL (`https://wiki.<ORG>.com/...`, `/spaces/<KEY>/pages/<ID>`, `/display/<KEY>/...`)
- Bare numeric page ID (usually 6-9 digits)
- User asks to look up, summarize, or search Confluence/wiki content
- Jira output includes wiki links (unless the user only asked for ticket metadata)

If a ticket links to 4+ pages, ask which pages to fetch first.

## Commands

- View a page: `wiki <URL-or-pageID>`
- Search: `wiki-search "query"` (up to 10 results)

`wiki` accepts both full URLs and raw page IDs.

## Output rules

For page view, render:
- `Title — Space (KEY)`
- Breadcrumb path (if present), version + last updated date, page URL
- Short summary of sections relevant to the user question

For search results, render each entry as:
`ID — Title (type, space) — URL`

- Preserve structure from CLI output (headings, lists, tables, code blocks, panels).
- Avoid dumping full long pages unless the user asks.
- Skip empty/null fields; never print raw JSON.

## Auth and errors

- `EVO_WIKI_PAT not set`: tell the user to source evolution dotfiles. Do not set tokens yourself.
- `HTTP 404`: page is deleted, moved, or inaccessible with current token. State that and stop (no ID guessing).

## Jira handoff

When Jira output includes wiki references:
1. Extract wiki URLs/page IDs from description/comments.
2. Fetch each page with `wiki`.
3. Pull relevant spec/AC/runbook details into the response.
4. Cite sources as `Title — URL`.
