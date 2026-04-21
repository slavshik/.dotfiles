#!/bin/bash
# Outputs 3 AI-generated commit message suggestions to stdout, one per line.
# Intended to be consumed by lazygit's menuFromCommand prompt.

# Route to an org-specific suggester if one exists (matches route_ai_commit.sh).
if git remote get-url origin 2>/dev/null | grep -q '\.evolution\.com' \
    && [ -x "$HOME/.dotfiles/evolution/aicommit-suggest.sh" ]; then
    exec "$HOME/.dotfiles/evolution/aicommit-suggest.sh"
fi

DIFF=$(git --no-pager diff --no-color --no-ext-diff --cached)

if [ -z "$DIFF" ]; then
    echo "No staged changes — stage files first." >&2
    exit 1
fi

SYSTEM="You are a commit message generator. Output exactly 3 Conventional Commits messages, one per line. No numbering, no bullets, no markdown, no quotes, no preamble."

aichat --prompt "$SYSTEM" "# Task
Suggest 3 distinct commit messages for the staged diff.

# Rules
- Format: <type>(optional scope): <description>
- Types: feat, fix, docs, style, refactor, perf, test, chore, build, ci
- Imperative mood, no trailing period
- Keep each line <= 72 characters

# Diff
\`\`\`diff
${DIFF}
\`\`\`" 2>/dev/null \
    | grep -E '^[a-z]+(\(.+\))?!?: .+'
