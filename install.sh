DOTFILES=~/.dotfiles
function dotlink() {
    ln -s $DOTFILES/$1 $2
}
dotlink zsh/zshrc ~/.zshrc
dotlink nvim/ ~/.config/nvim
dotlink tmux.conf ~/.tmux.conf
dotlink alacritty ~/.config/alacritty
dotlink karabiner ~/.config/karabiner
dotlink .gitconfig ~/.gitconfig
# git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
./defaults_write.sh
