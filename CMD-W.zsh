#!/bin/zsh
LOGFILE="/Users/slavshik/Desktop/$(date).txt"
touch $LOGFILE
echo "Log file created at $(date)" >> $LOGFILE
echo "TMUX is $TMUX " >> $LOGFILE
echo "VIM is $VIM" >> $LOGFILE
echo "LOGFILE is $LOGFILE" >> $LOGFILE
#if [ $VIM ]; then
#    echo "$0"
#    nvim --server "$VIM" --remote-send ":q<CR>"
#    exit 0;
#fi
#
if [ $TMUX ]; then
    tmux kill-pane;
    exit 0;
fi
#
#osascript -e 'tell application "Alacritty" to quit'
