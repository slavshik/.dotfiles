#!/bin/bash
DOTFILES=~/.dotfiles

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

ok()   { echo -e "  ${GREEN}✔${NC} $1"; }
fail() { echo -e "  ${RED}✘${NC} $1"; }

function dotlink() {
    if ln -sfn "$DOTFILES/$1" "$2" 2>/dev/null; then
        ok "link $2"
    else
        fail "link $2"
    fi
}

function clone_if_missing() {
    local repo="$1" dest="$2" label="$3"
    if [ -d "$dest" ]; then
        ok "$label (already installed)"
    elif GIT_TERMINAL_PROMPT=0 git clone "$repo" "$dest" --quiet --depth 1 2>/dev/null; then
        ok "$label"
    else
        fail "$label"
    fi
}

echo "Symlinks:"
dotlink zsh/zshrc ~/.zshrc
dotlink nvim/ ~/.config/nvim
dotlink tmux/tmux.conf ~/.tmux.conf
dotlink alacritty/ ~/.config/alacritty
dotlink lf/ ~/.config/lf
dotlink sesh/ ~/.config/sesh
dotlink lsd/ ~/.config/lsd
dotlink karabiner/ ~/.config/karabiner
dotlink .gitconfig ~/.gitconfig
dotlink .gitignore_system ~/.gitignore
dotlink .ideavimrc ~/.ideavimrc
# lazygit
dotlink lazygit/config.yml ~/Library/Application\ Support/lazygit/config.yml
dotlink lazygit/state.yml ~/Library/Application\ Support/lazygit/state.yml
# claude
dotlink claude/skills ~/.claude/skills
dotlink claude/statusline-command.sh ~/.claude/statusline-command.sh
dotlink claude/settings.json ~/.claude/settings.json

echo ""
echo "CLI links:"
mkdir -p ~/.local/bin
if ln -sf "/Applications/Sublime Text.app/Contents/SharedSupport/bin/subl" ~/.local/bin/subl 2>/dev/null; then
    ok "subl → ~/.local/bin/subl"
else
    fail "subl → ~/.local/bin/subl"
fi

echo ""
echo "macOS defaults:"
if ./defaults_write.sh >/dev/null 2>&1; then
    ok "defaults_write.sh"
else
    fail "defaults_write.sh"
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

echo ""
echo "Git clones:"
clone_if_missing https://github.com/jimeh/tmuxifier.git \
    ~/.tmuxifier "tmuxifier"
clone_if_missing https://github.com/romkatv/powerlevel10k.git \
    "${ZSH_CUSTOM}/themes/powerlevel10k" "powerlevel10k"
clone_if_missing https://github.com/zsh-users/zsh-autosuggestions \
    "${ZSH_CUSTOM}/plugins/zsh-autosuggestions" "zsh-autosuggestions"
clone_if_missing https://github.com/tmux-plugins/tpm \
    ~/.tmux/plugins/tpm "tpm (tmux plugin manager)"
