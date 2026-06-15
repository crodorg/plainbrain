#!/usr/bin/env bash
# SessionStart hook. stdout is injected into the session as context.
# Inert unless the repo is plainbrain-activated (a `.claude/plainbrain` marker, dropped
# by adopt-project). Un-activated repos get nothing — throwaway sessions leave no trace.
set -u

root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0   # not a git repo: nothing to do
cd "$root" || exit 0
[ -f .claude/plainbrain ] || exit 0                            # not activated: stay out of the way
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

WIKI="${PLAINBRAIN_WIKI:-$HOME/wiki}"
if [ -d "$WIKI" ]; then
  echo
  echo "### Wiki"
  echo "$(find "$WIKI" -name '*.md' ! -path '*/_lint/*' | wc -l | tr -d ' ') pages — relevant ones auto-surface by tag on Bash calls; /wiki-query to search"
fi

if [ -f .claude/state/.pending-distill ]; then
  echo
  echo "### Pending reconcile"
  echo "An earlier session ended with unsaved work. Those changes are still in the working"
  echo "tree (see Git above) and were backed up to refs/plainbrain/wip/ — recoverable with"
  echo "\`plainbrain wip\`. Before starting new work, ASK THE USER what to do:"
  echo "  a) distill — run the distill skill now to fold it into durable memory"
  echo "     (in ~/wiki: run wiki-lint instead)"
  echo "  b) keep accumulating — proceed; distill later"
  echo "  c) discard — drop the dirty changes (destructive; only with explicit confirmation)"
fi
exit 0
