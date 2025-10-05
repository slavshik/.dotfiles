aichat "Please suggest 3 commit messages, given the following diff:

        \`\`\`diff
       `git --no-pager diff --no-color --no-ext-diff --cached`     
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

    Just commit message and nothing else, without index number and newlines between.
    Write your 3 commit messages below in the format shown in Output Template section above." \
          | fzf --height 40% --border --ansi --preview "echo {}" --preview-window=up:wrap \
          | xargs -S1024 -I {} bash -c '
              COMMIT_MSG_FILE=$(mktemp)
              echo "{}" > "$COMMIT_MSG_FILE"
              ${EDITOR:-vim} "$COMMIT_MSG_FILE"
              if [ -s "$COMMIT_MSG_FILE" ]; then
                  git commit -F "$COMMIT_MSG_FILE"
              else
                  echo "Commit message is empty, commit aborted."
              fi
              rm -f "$COMMIT_MSG_FILE"'

