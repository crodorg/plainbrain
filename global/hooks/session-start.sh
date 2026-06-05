#!/usr/bin/env bash
# SessionStart hook. stdout is injected into the session as context.
# Keep it fast and small — this runs on every launch and resume.
set -u

root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0   # not a git repo: nothing to do
cd "$root" || exit 0
mkdir -p .claude/state
date +%s > .claude/state/.session-start

echo "## Session context: $(basename "$root")"
echo
echo "### Git"
git status --short 2>/dev/null | head -20
echo
git log --oneline -5 2>/dev/null
echo
if [ -f plan.md ]; then
  echo "### Driver: read ./plan.md — it is the driver for this project."
elif [ -f CONTEXT.md ]; then
  echo "### Driver: read ./CONTEXT.md — it is the driver for this project."
fi

if [ -f .claude/state/.pending-save ]; then
  echo
  echo "### Pending reconcile"
  last=0
  [ -f .claude/state/.last-save ] && last=$(cat .claude/state/.last-save 2>/dev/null || echo 0)
  echo "Earlier session(s) ended with unsaved work (auto-committed as wip)."
  echo "Commits since the last save-context:"
  if [ "${last:-0}" -gt 0 ] 2>/dev/null; then
    git log -50 --format='%ct%x09%h %ad %s' --date=format:'%Y-%m-%d %H:%M' 2>/dev/null \
      | awk -F'\t' -v last="$last" '$1+0 > last+0 { print "- " $2 }'
  else
    git log -10 --format='%h %ad %s' --date=format:'%Y-%m-%d %H:%M' --grep='^wip:' 2>/dev/null \
      | sed 's/^/- /'
  fi
  echo
  echo "Before starting new work, ASK THE USER what to do with these:"
  echo "  a) distill — run the save-context skill now (in ~/wiki: run wiki-lint instead)"
  echo "  b) keep accumulating — proceed with new work; save later"
  echo "  c) discard — revert the wip commits (destructive; only with explicit confirmation)"
fi
exit 0
