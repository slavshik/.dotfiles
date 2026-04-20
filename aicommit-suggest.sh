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

aichat "Please suggest 3 commit messages, given the following diff:

\`\`\`diff
${DIFF}
\`\`\`

**Criteria:**

\`\`\`
<type>(optional scope): <description>
\`\`\`

 - \`<type>\`: This defines the nature of the commit and is typically one of these:
     - feat: A new feature
     - fix: A bug fix
     - docs: Documentation-only changes
     - style: Changes that do not affect the meaning of the code (white-space, formatting, missing semi-colons, etc.)
     - refactor: A code change that neither fixes a bug nor adds a feature
     - perf: A code change that improves performance
     - test: Adding missing tests or correcting existing tests
     - chore: Changes to the build process or auxiliary tools and libraries such as documentation generation
     - build: Changes that affect the build system or external dependencies
     - ci: Changes to CI configuration files and scripts

Output exactly 3 commit messages, one per line, with no numbering, no bullets, no blank lines, and no extra commentary." 2>/dev/null
