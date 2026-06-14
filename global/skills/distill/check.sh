#!/bin/sh
# check.sh — deterministic distill pre-check. No AI, no network.
# Answers: is there anything left to save this session? Reads the existing
# .claude/state/.session-start marker + git. First line is the verdict:
#   UNSAVED              dirty working tree                          -> full skill
#   COMMITS-NO-DURABLES  clean, but no durable file committed since  -> full skill
#                        session start (or no marker to scope by)
#   SAVED                clean; durable files committed this session -> fast path
#   CLEAN                clean; no commits this session              -> fast path
# Always exits 0.

root=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "UNSAVED: not a git repo"; exit 0; }
cd "$root" || exit 0

dirty=$(git status --porcelain 2>/dev/null)
if [ -n "$dirty" ]; then
  echo "UNSAVED: working tree dirty"
  printf '%s\n' "$dirty" | head -20
  exit 0
fi

start=0
[ -f .claude/state/.session-start ] && start=$(cat .claude/state/.session-start 2>/dev/null || echo 0)
if [ "${start:-0}" -le 0 ] 2>/dev/null; then
  echo "COMMITS-NO-DURABLES: no session-start marker; cannot scope to this session"
  exit 0
fi

# Commits since session start (same %ct + awk pattern as session-start-git.sh).
commits=$(git log -100 --format='%ct%x09%h %s' 2>/dev/null \
  | awk -F'\t' -v s="$start" '$1+0 > s+0 { print $2 }')
if [ -z "$commits" ]; then
  echo "CLEAN: tree clean, no commits this session"
  exit 0
fi

hashes=$(printf '%s\n' "$commits" | awk '{ print $1 }')
# shellcheck disable=SC2086 — word-splitting of $hashes is intended
durables=$(git show --name-only --format= $hashes 2>/dev/null | sort -u \
  | grep -E '^(decisions\.md|plan\.md|CONTEXT\.md|ARCHITECTURE\.md)$')

if [ -n "$durables" ]; then
  echo "SAVED: tree clean; durable files committed this session:"
  printf '%s\n' "$durables" | sed 's/^/  /'
else
  echo "COMMITS-NO-DURABLES: tree clean, but no durable file updated this session"
fi
echo "session commits:"
printf '%s\n' "$commits" | sed 's/^/  - /'
exit 0
