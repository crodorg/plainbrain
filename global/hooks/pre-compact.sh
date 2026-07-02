#!/usr/bin/env bash
# PreCompact hook. Fires right before context is compacted (manual /compact or auto).
# Byte-safety only: snapshot the FULL working tree — tracked AND untracked — to a PRIVATE ref so
# nothing is lost — no branch commit, no model needed. Compaction summarizes the conversation,
# not the files, so this is belt-and-suspenders; recoverable via `plainbrain wip`.
# Inert unless the repo is plainbrain-activated.
set -u

root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
cd "$root" || exit 0
[ -f .claude/plainbrain ] || exit 0

# Key the snapshot ref by the session_id from the hook payload (stdin JSON), so concurrent
# sessions in one repo get distinct refs. Fall back to the shared session-start timestamp
# (stable within a session) when there's no id.
payload=""; [ -t 0 ] || payload=$(cat 2>/dev/null)   # read the hook payload; never block on a tty
sid=$(printf '%s' "$payload" | tr '\n' ' ' \
  | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | tr -cd 'A-Za-z0-9_.-')
[ -z "$sid" ] && [ -f .claude/state/.session-start ] && sid="ts$(tr -cd '0-9' < .claude/state/.session-start)"
[ -z "$sid" ] && sid="ts$(date +%s)"

. "$(dirname "$0")/wip-lib.sh" 2>/dev/null || exit 0
pb_wip_snapshot "$sid" "plainbrain pre-compact $sid"
exit 0
