#!/bin/bash
defaults write -g ApplePressAndHoldEnabled -bool false
defaults write -g InitialKeyRepeat -int 10 # normal minimum is 15 (225 ms)
defaults write -g KeyRepeat -int 1 # normal minimum is 2 (30 ms)

# Free CMD+H and CMD+Alt+H for Alacritty's tmux navigation (nav-left / swap-left).
# macOS routes these to the app menu's "Hide <app>" (⌘H) and "Hide Others" (⌘⌥H),
# which fire BEFORE Alacritty's keybindings can see the keypress. Reassigning those
# menu items to an unused hyper-combo frees ⌘H / ⌘⌥H so they fall through to Alacritty.
# NOTE: winit titles the Hide item "Hide " + the *executable* name -> "Hide alacritty"
# (lowercase), NOT the bundle name. The title must match exactly or the override is ignored.
# Takes effect after Alacritty is fully quit and relaunched (menu is built at launch).
defaults write org.alacritty NSUserKeyEquivalents '{ "Hide alacritty" = "@~^h"; "Hide Others" = "@~^o"; }'

# to enable TouchID in terminal:
# sudo nvim /etc/pam.d/sudo_local
# auth       optional       /opt/homebrew/lib/pam/pam_reattach.so
# auth       sufficient     pam_tid.so
