#!/usr/bin/env bash
# SessionEnd hook. Fires on /exit and other clean terminations.
# If the tree is dirty, snapshot ALL work — tracked AND untracked — to a PRIVATE ref
# (recoverable backup, never a branch commit) and raise a flag so the next SessionStart offers
# to reconcile it. A clean tree (e.g. after a complete distill) does nothing. Inert unless the
# repo is plainbrain-activated.
set -u

root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
cd "$root" || exit 0
[ -f .claude/plainbrain ] || exit 0
mkdir -p .claude/state

# Key the snapshot ref by session_id (from the stdin payload) so concurrent sessions in one
# repo get distinct refs. Fall back to this session's start marker, else a timestamp.
payload=""; [ -t 0 ] || payload=$(cat 2>/dev/null)   # read the hook payload; never block on a tty
sid=$(printf '%s' "$payload" | tr '\n' ' ' \
  | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | tr -cd 'A-Za-z0-9_.-')
ref="$sid"
[ -z "$ref" ] && [ -f .claude/state/.session-start ] && ref="ts$(tr -cd '0-9' < .claude/state/.session-start)"
[ -z "$ref" ] && ref="ts$(date +%s)"

# Snapshot on ANY dirty exit and raise the reconcile flag. (This was gated on "distill didn't
# run this session" via a shared .last-distill marker — but that both skipped post-distill
# leftovers the distill skill promises to catch and let concurrent sessions suppress each
# other's snapshot. A clean tree already no-ops, so the gate only ever suppressed real dirt.)
. "$(dirname "$0")/wip-lib.sh" 2>/dev/null || exit 0
if pb_wip_snapshot "$ref" "plainbrain session-end $ref"; then
  : > .claude/state/.pending-distill
fi
exit 0
