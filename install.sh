DOTFILES=~/.dotfiles
function dotlink() {
    ln -sfn $DOTFILES/$1 $2
}
dotlink zsh/zshrc ~/.zshrc
dotlink nvim/ ~/.config/nvim
dotlink tmux/tmux.conf ~/.tmux.conf
dotlink alacritty/ ~/.config/alacritty
dotlink karabiner/ ~/.config/karabiner
dotlink .gitconfig ~/.gitconfig
# git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
./defaults_write.sh
# TODO: install packer and brew dependencies
