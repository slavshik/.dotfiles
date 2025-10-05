aichat "Please suggest 3 commit messages, given the following diff:

        \`\`\`diff
        $(git --no-pager diff --no-color --no-ext-diff --cached)     
        \`\`\`

        **Criteria:**

        1. **Format:** Should comply conventional commits format
        Just commit messages list and nothing else. 

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

