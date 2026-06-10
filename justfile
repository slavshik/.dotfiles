# Show recipes
@default:
    just --list

# Symlink configs, build CLIs, set macOS defaults
install:
    ./install.sh

# Parse-check all zsh files
lint-zsh:
    #!/usr/bin/env zsh
    for f in zsh/zshrc zsh/zshrc.agent.zsh zsh/*.zsh zsh/scripts/*.zsh lf/lfcd.sh daily-summary.sh; do
      zsh -n "$f" || exit 1
    done
    echo "zsh syntax OK"

# Shellcheck bash/sh scripts (same set and flags as CI)
lint-sh:
    git ls-files '*.sh' | grep -v '^zsh/' | grep -v '^lf/' | grep -v 'daily-summary.sh' | xargs npx -y shellcheck --severity=warning -e SC1090,SC1091

lint: lint-zsh lint-sh
