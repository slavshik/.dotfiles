defaults write -g ApplePressAndHoldEnabled -bool false
defaults write -g InitialKeyRepeat -int 10 # normal minimum is 15 (225 ms)
defaults write -g KeyRepeat -int 1 # normal minimum is 2 (30 ms)

# to enable TouchID in terminal:
# sudo nvim /etc/pam.d/sudo_local
# auth       optional       /opt/homebrew/lib/pam/pam_reattach.so
# auth       sufficient     pam_tid.so
