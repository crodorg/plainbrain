#!/usr/bin/env bash
# gate.sh — deterministic enforcement gates. OPT-IN: inert unless the repo carries a
# `.claude/plainbrain` marker with an `enforce: on` line. No AI, no network — every gate
# is a file-existence, mtime, or glob check. Gates bound what a drifting agent can DO;
# they are guardrails for the honest path, not a sandbox (the Bash tool can still write
# files — the harness permission system stays the hard wall for that).
#
# Fired two ways, same script:
#   Claude Code  settings.json  PreToolUse (Read|Edit|Write|MultiEdit|NotebookEdit) + Stop
#   Pi           extension      tool_call (read/edit/write, normalized by the adapter)
#
# Payload: Claude-shaped JSON on stdin. Verdicts on stdout, always exit 0:
#   PreToolUse deny -> {"hookSpecificOutput":{"permissionDecision":"deny",...}}
#   Stop block      -> {"decision":"block","reason":...}
#   allow           -> no output
#
# Gates (all need a named driver; a core-only project is exercised but inert):
#   driver-read   no Edit/Write until the driver was Read this session
#   plan-rewrite  no edit to the driver until the why is on record this session
#                 (decisions.scratch or decisions.md touched since session start)
#   scope         when the driver carries a `scope: <globs>` line, edits must match it
#   stop          plan.md changed this session -> .claude/state/next.md must be refreshed
#
# Hard rule: FAIL OPEN. Any unexpected state allows — a broken gate must never cost a turn.
set -u

root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
cd "$root" || exit 0
[ -f .claude/plainbrain ] || exit 0
grep -q '^enforce:[[:space:]]*on' .claude/plainbrain || exit 0

payload=""; [ -t 0 ] || payload=$(cat 2>/dev/null)
[ -n "$payload" ] || exit 0

# Field extraction: python3 when present (exact); else first-match grep. Top-level fields
# precede tool_input in the payload, and file_path leads tool_input, so the first match is
# the field itself — not an echo of it inside file *content* being written.
jget() {
  if command -v python3 >/dev/null 2>&1; then
    printf '%s' "$payload" | python3 -c '
import json,sys
try: d = json.load(sys.stdin)
except Exception: sys.exit(0)
for k in sys.argv[1:]:
    d = d.get(k) if isinstance(d, dict) else None
    if d is None: sys.exit(0)
print(d)' "$@" 2>/dev/null
  else
    printf '%s' "$payload" | tr '\n' ' ' \
      | grep -o "\"${!#}\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | head -1 \
      | sed 's/.*:[[:space:]]*"\(.*\)"/\1/'
  fi
}

json_escape() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }

deny() {
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' \
    "$(json_escape "$1")"
  exit 0
}

event=$(jget hook_event_name); [ -n "$event" ] || exit 0
sid=$(jget session_id | tr -cd 'A-Za-z0-9_.-')   # same sanitizing as session-start.sh

# Session-start marker for "this session" mtime scoping (written by session-start.sh).
sm=""
[ -n "$sid" ] && [ -f ".claude/state/sessions/$sid.start" ] && sm=".claude/state/sessions/$sid.start"
[ -z "$sm" ] && [ -f .claude/state/.session-start ] && sm=".claude/state/.session-start"

# Driver resolution — identical to session-start.sh.
driver=$(sed -n 's/^driver:[[:space:]]*//p' .claude/plainbrain 2>/dev/null | head -1 | tr -d '[:space:]')
if [ -z "$driver" ]; then
  [ -f plan.md ] && driver="plan.md"
  [ -z "$driver" ] && [ -f CONTEXT.md ] && driver="CONTEXT.md"
fi
[ -n "$driver" ] && [ ! -f "$driver" ] && driver=""

case "$event" in

PreToolUse)
  [ -n "$driver" ] || exit 0                       # nothing to enforce against
  tool=$(jget tool_name | tr 'A-Z' 'a-z')
  fp=$(jget tool_input file_path)
  [ -z "$fp" ] && fp=$(jget tool_input notebook_path)
  [ -n "$fp" ] || exit 0                           # not a file tool: never gated

  # Repo-relative target. Claude Code and the Pi adapter both send absolute paths;
  # a relative path is treated as root-relative. Outside the repo -> not ours to gate.
  case "$fp" in
    "$root"/*) rel="${fp#"$root"/}" ;;
    /*) exit 0 ;;
    ../*) exit 0 ;;
    *) rel="$fp" ;;
  esac

  # Reading the driver marks it read for this session.
  if [ "$tool" = "read" ]; then
    if [ "$rel" = "$driver" ]; then
      mkdir -p .claude/state/sessions
      touch .claude/state/.driver-read
      [ -n "$sid" ] && touch ".claude/state/sessions/$sid.driver-read"
    fi
    exit 0
  fi
  case "$tool" in edit|write|multiedit|notebookedit) ;; *) exit 0 ;; esac

  # Rationale and ephemeral state are never blocked — parking the why must stay free.
  case "$rel" in .claude/*|decisions.md|decisions-*.md) exit 0 ;; esac

  # --- driver-read ------------------------------------------------------------
  read_ok=0
  if [ -n "$sid" ]; then
    [ -f ".claude/state/sessions/$sid.driver-read" ] && read_ok=1
  elif [ -f .claude/state/.driver-read ]; then
    { [ -z "$sm" ] || [ .claude/state/.driver-read -nt "$sm" ]; } && read_ok=1
  fi
  [ $read_ok -eq 0 ] && deny "./$driver is this project's driver and hasn't been read this session. Read ./$driver, then retry. (plainbrain gate: driver-read)"

  # --- plan-rewrite -----------------------------------------------------------
  if [ "$rel" = "$driver" ] && [ -n "$sm" ]; then   # creating a driver, or no session marker: allowed
    why_ok=0
    [ -f .claude/state/decisions.scratch ] && [ .claude/state/decisions.scratch -nt "$sm" ] && why_ok=1
    [ -f decisions.md ] && [ decisions.md -nt "$sm" ] && why_ok=1
    [ $why_ok -eq 0 ] && deny "Changing ./$driver needs the why on record first: append one line to .claude/state/decisions.scratch (or decisions.md), then retry. (plainbrain gate: plan-rewrite)"
  fi

  # --- scope ------------------------------------------------------------------
  # Active only when the driver declares `scope: <glob> <glob> ...` (first such line).
  # Kit prose files stay editable; everything else must match a glob.
  if [ "$rel" != "$driver" ]; then
    scope=$(sed -n 's/^scope:[[:space:]]*//p' "$driver" 2>/dev/null | head -1)
    if [ -n "$scope" ]; then
      case "$rel" in AGENTS.md|README.md|ARCHITECTURE.md|CONTEXT.md|plan.md|.gitignore) exit 0 ;; esac
      ok=0
      set -f                                        # keep globs literal for `case`
      for g in $scope; do
        # shellcheck disable=SC2254 — unquoted $g is the point: case does the glob match
        case "$rel" in $g) ok=1 ;; esac
      done
      # Explicit user ask outside scope: honored via a LOGGED override — an
      # `override: <why> <path-or-glob>` line written to decisions.scratch this session
      # (distill folds it into decisions.md, so the exception stays on the record).
      if [ $ok -eq 0 ] && [ -f .claude/state/decisions.scratch ] \
        && { [ -z "$sm" ] || [ .claude/state/decisions.scratch -nt "$sm" ]; }; then
        while IFS= read -r ov; do
          case "$ov" in override:*) ;; *) continue ;; esac
          for g in ${ov#override:}; do
            case "$rel" in $g) ok=1 ;; esac
          done
        done < .claude/state/decisions.scratch
      fi
      set +f
      [ $ok -eq 0 ] && deny "$rel is outside the plan's current scope (scope: $scope in ./$driver). If the user explicitly asked for this, append one line 'override: <why> $rel' to .claude/state/decisions.scratch and retry. Otherwise work within scope, or widen the scope line in ./$driver — a plan change: log why first. (plainbrain gate: scope)"
    fi
  fi
  exit 0
  ;;

Stop)
  # One nudge only: if we already blocked once this stop, let it through.
  printf '%s' "$payload" | grep -q '"stop_hook_active"[[:space:]]*:[[:space:]]*true' && exit 0
  [ "$driver" = "plan.md" ] || exit 0
  [ -n "$sm" ] || exit 0
  [ "$driver" -nt "$sm" ] || exit 0                # plan untouched this session: fine
  [ -f .claude/state/next.md ] && [ .claude/state/next.md -nt "$sm" ] && exit 0
  printf '{"decision":"block","reason":"%s"}\n' \
    "$(json_escape "plan.md changed this session but .claude/state/next.md wasn't refreshed. Overwrite it (STEP/OPEN/RESUME lines per the plan loop), then finish. (plainbrain gate: stop)")"
  exit 0
  ;;

esac
exit 0
