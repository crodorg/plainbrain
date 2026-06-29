#!/usr/bin/env bash
# SessionEnd hook. Fires on /exit and other clean terminations.
# If distill did NOT run this session and the tree is dirty, snapshot tracked work to a
# PRIVATE ref (recoverable backup, no branch commit) and raise a flag so the next
# SessionStart reminds you to distill. Inert unless the repo is plainbrain-activated.
set -u

root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
cd "$root" || exit 0
[ -f .claude/plainbrain ] || exit 0
mkdir -p .claude/state

# session_id from the hook payload (stdin JSON): keys this session's start marker and its wip
# ref, so concurrent sessions in one repo can't clobber each other. Falls back to the shared
# timestamp file when there's no id.
payload=$(cat 2>/dev/null)
sid=$(printf '%s' "$payload" | tr '\n' ' ' \
  | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | tr -cd 'A-Za-z0-9_.-')

start=0; last=0
if [ -n "$sid" ] && [ -f ".claude/state/sessions/$sid.start" ]; then
  start=$(cat ".claude/state/sessions/$sid.start" 2>/dev/null || echo 0)   # this session's start
elif [ -f .claude/state/.session-start ]; then
  start=$(cat .claude/state/.session-start 2>/dev/null || echo 0)          # fallback: shared pointer
fi
[ -f .claude/state/.last-distill ] && last=$(cat .claude/state/.last-distill 2>/dev/null || echo 0)

# Ref key: session_id when present (no cross-session clobber), else the stable start timestamp.
ref="$sid"; [ -z "$ref" ] && ref="ts$start"

# Only when distill didn't run this session (last < start) AND the tree is dirty in any way.
# Untracked-only dirt still flags pending (the files are safe on disk); the snapshot itself
# captures tracked changes — never sweeps untracked drafts.
if [ "${last:-0}" -lt "${start:-0}" ] && [ -n "$(git status --porcelain 2>/dev/null)" ]; then
  sha=$(git stash create "plainbrain session-end $ref" 2>/dev/null)
  [ -n "$sha" ] && git update-ref "refs/plainbrain/wip/$ref" "$sha" 2>/dev/null
  : > .claude/state/.pending-distill
fi
exit 0
