#!/usr/bin/env bash
# PreCompact hook. Fires right before context is compacted (manual /compact or auto).
# Job: never lose progress. Commit a WIP snapshot deterministically. No model needed.
set -u

root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
cd "$root" || exit 0

if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
  git add -A 2>/dev/null
  git commit -q -m "wip: pre-compact snapshot $(date -u +%Y-%m-%dT%H:%M:%SZ)" 2>/dev/null || true
fi
exit 0
