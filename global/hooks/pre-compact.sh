#!/usr/bin/env bash
# PreCompact hook. Fires right before context is compacted (manual /compact or auto).
# Byte-safety only: snapshot the working tree to a PRIVATE ref so nothing is lost —
# no branch commit, no model needed. Compaction summarizes the conversation, not the
# files, so this is belt-and-suspenders; the snapshot is recoverable via `plainbrain wip`.
# Inert unless the repo is plainbrain-activated.
set -u

root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
cd "$root" || exit 0
[ -f .claude/plainbrain ] || exit 0

# Key the snapshot ref by the session_id from the hook payload (stdin JSON), so concurrent
# sessions in one repo get distinct refs instead of silently overwriting each other. Fall
# back to the shared session-start timestamp (stable within a session) when there's no id.
payload=$(cat 2>/dev/null)
sid=$(printf '%s' "$payload" | tr '\n' ' ' \
  | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | tr -cd 'A-Za-z0-9_.-')
[ -z "$sid" ] && [ -f .claude/state/.session-start ] && sid="ts$(tr -cd '0-9' < .claude/state/.session-start)"
[ -z "$sid" ] && sid="ts$(date +%s)"
# git stash create builds a stash-format commit from tracked changes WITHOUT touching the
# working tree or any branch; empty output means nothing tracked to snapshot.
sha=$(git stash create "plainbrain pre-compact $sid" 2>/dev/null)
[ -n "$sha" ] && git update-ref "refs/plainbrain/wip/$sid" "$sha" 2>/dev/null
exit 0
