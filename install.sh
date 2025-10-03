DOTFILES=~/.dotfiles
function dotlink() {
    ln -sfn $DOTFILES/$1 $2
}
dotlink zsh/zshrc ~/.zshrc
dotlink nvim/ ~/.config/nvim
dotlink tmux/tmux.conf ~/.tmux.conf
dotlink alacritty/ ~/.config/alacritty
dotlink lf/ ~/.config/lf
dotlink karabiner/ ~/.config/karabiner
dotlink .gitconfig ~/.gitconfig
dotlink .gitignore_system ~/.gitignore
dotlink .ideavimrc ~/.ideavimrc
dotlink sesh/ ~/.config/sesh
# git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
./defaults_write.sh
# TODO: install packer and brew dependencies

ln -sfn $DOTFILES/lazygit/config.yml ~/Library/Application\ Support/lazygit/config.yml
ln -sfn $DOTFILES/lazygit/state.yml ~/Library/Application\ Support/lazygit/state.yml
