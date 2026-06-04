#!/usr/bin/env bash
# SessionEnd hook. Fires on /exit and other clean terminations.
# If the save-context skill did NOT run this session, snapshot the bytes deterministically
# and raise a flag so the next SessionStart reminds you to do the real (semantic) save.
set -u

root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
cd "$root" || exit 0
mkdir -p .claude/state

start=0; last=0
[ -f .claude/state/.session-start ] && start=$(cat .claude/state/.session-start 2>/dev/null || echo 0)
[ -f .claude/state/.last-save ]     && last=$(cat .claude/state/.last-save 2>/dev/null || echo 0)

# Rescue + flag only when there's genuine unsaved work AND no explicit save ran this session.
# (If a skill already committed everything, the tree is clean and we stay quiet.)
if [ "${last:-0}" -lt "${start:-0}" ] && [ -n "$(git status --porcelain 2>/dev/null)" ]; then
  git add -A 2>/dev/null
  git commit -q -m "wip: auto-save on exit $(date -u +%Y-%m-%dT%H:%M:%SZ)" 2>/dev/null || true
  : > .claude/state/.pending-save
fi
exit 0
