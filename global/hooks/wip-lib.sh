# wip-lib.sh — shared WIP-snapshot helper for the plainbrain lifecycle hooks.
# NOT a hook itself (nothing in settings.json invokes it); session-end.sh and pre-compact.sh
# source it. It snapshots the FULL working tree — tracked changes AND untracked files — to a
# private ref as a stash-format commit, WITHOUT touching the index or working tree, so
# `plainbrain recover` (git stash apply) restores everything. `git stash create` alone captures
# only tracked changes; this grafts the untracked files on as the stash's third parent, exactly
# as `git stash -u` does, so recovery is unchanged.

# pb_wip_snapshot REF LABEL — write refs/plainbrain/wip/REF from the current working tree.
# Returns 0 if a snapshot was written, 1 if the tree was clean (nothing to save).
pb_wip_snapshot() {
  _ref="$1"; _label="$2"
  [ -n "$(git status --porcelain 2>/dev/null)" ] || return 1

  # Untracked files (excluding gitignored) -> a tree, staged via a THROWAWAY index so the real
  # index and working tree are never touched.
  _u=""
  if [ -n "$(git ls-files --others --exclude-standard 2>/dev/null)" ]; then
    _ui="$(git rev-parse --git-dir)/plainbrain-untracked-index"; rm -f "$_ui"
    git ls-files --others --exclude-standard -z \
      | GIT_INDEX_FILE="$_ui" git update-index --add -z --stdin 2>/dev/null
    _ut=$(GIT_INDEX_FILE="$_ui" git write-tree 2>/dev/null); rm -f "$_ui"
    [ -n "$_ut" ] && _u=$(git commit-tree "$_ut" -m "untracked files" 2>/dev/null)
  fi

  # Tracked changes: let git build the stash commit (working tree + index parents), then graft
  # the untracked commit on as a third parent so `git stash apply` restores it too.
  _s=$(git stash create "$_label" 2>/dev/null)
  if [ -n "$_u" ]; then
    if [ -n "$_s" ]; then
      _s=$(git commit-tree "$(git rev-parse "$_s^{tree}")" \
             -p "$(git rev-parse "$_s^1")" -p "$(git rev-parse "$_s^2")" -p "$_u" \
             -m "$_label" 2>/dev/null)
    else
      # Tracked tree clean, untracked-only: synthesize a stash whose base tree is HEAD's.
      _ht=$(git rev-parse "HEAD^{tree}" 2>/dev/null)
      _ic=$(git commit-tree "$_ht" -p HEAD -m "index" 2>/dev/null)
      _s=$(git commit-tree "$_ht" -p HEAD -p "$_ic" -p "$_u" -m "$_label" 2>/dev/null)
    fi
  fi

  [ -n "$_s" ] || return 1
  git update-ref "refs/plainbrain/wip/$_ref" "$_s" 2>/dev/null
}
