#!/bin/sh
input=$(cat)

# ANSI 256-color helpers
c()  { printf "\033[38;5;%sm" "$1"; }  # foreground color
dim= ; reset="\033[0m"
sep=$(printf "\033[38;5;238m\033[0m")  # dark-gray separator

# Segment colors
col_user=73    # muted teal
col_path=179   # warm amber
col_branch=141 # soft lavender
col_model=110  # steel blue

user=$(whoami)
host=$(hostname -s)
dir=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
short_dir=$(echo "$dir" | awk -F'/' '{if(NF>2) print $(NF-1)"/"$NF; else print $0}')
model=$(echo "$input" | jq -r '.model.display_name // ""')

# Context % — green (107) below 70%, yellow-orange (179) 70-89%, red-orange (173) 90%+
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
if [ -n "$used" ]; then
    used_int=$(printf "%.0f" "$used")
    if [ "$used_int" -ge 90 ]; then
        col_ctx=173
    elif [ "$used_int" -ge 70 ]; then
        col_ctx=179
    else
        col_ctx=107
    fi
    ctx_str=$(printf "$(c $col_ctx)ctx:%s%%${reset}" "$used_int")
else
    ctx_str=""
fi

# Git branch (skip optional lock files)
branch=$(GIT_DIR="$dir/.git" git --git-dir="$dir/.git" -c gc.auto=0 rev-parse --abbrev-ref HEAD 2>/dev/null)
if [ -n "$branch" ]; then
    branch_str=$(printf " $(c $col_branch)(${branch})${reset}")
else
    branch_str=""
fi

# Assemble
printf "$(c $col_user)%s@%s${reset} $(c $col_path)%s${reset}%s ${sep}${reset} $(c $col_model)%s${reset}" \
    "$user" "$host" "$short_dir" "$branch_str" "$model"

if [ -n "$ctx_str" ]; then
    printf " ${sep}${reset} %s" "$ctx_str"
fi
