# dotup — update dotfiles, then re-run install.sh only if it changed.
# Reliable across merge/rebase/fast-forward (this repo has pull.rebase=true,
# so post-merge/post-rewrite hooks would not fire on a fast-forward pull).
dotup() {
  local dir="${1:-$HOME/.dotfiles}" before after changed
  before=$(git -C "$dir" rev-parse HEAD) || return
  git -C "$dir" pull --rebase || return
  after=$(git -C "$dir" rev-parse HEAD)
  [[ "$before" == "$after" ]] && return                  # nothing pulled
  changed=$(git -C "$dir" diff --name-only "$before" "$after")
  if grep -qx 'install.sh' <<< "$changed"; then
    echo "↻ install.sh changed — re-running"
    (cd "$dir" && ./install.sh)
  fi
  if grep -qx 'Brewfile' <<< "$changed"; then
    echo "⚠ Brewfile changed — review new packages"
  fi
}
