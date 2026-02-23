#!/bin/bash

if git remote get-url origin | grep -q "\.evolution\.com"; then
   sh ~/.dotfiles/evolution/aicommit.sh
else
   sh ~/.dotfiles/aicommit.sh
fi
