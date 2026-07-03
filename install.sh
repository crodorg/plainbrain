#!/bin/sh
# plainbrain installer — idempotent, backup-first, POSIX sh, no hard deps.
#   ./install.sh            full setup (homes, config, hooks, skills, CLI, template)
#   ./install.sh --update   refresh only the kit-owned files (hooks, skills, CLI, template)
#   flags: --pi / --no-pi   force-enable / -disable the Pi harness target (default: auto-detect)
#
# Never clobbers your data or merged config: an existing wiki, ~/.config/opencode/AGENTS.md,
# ~/.pi/agent/AGENTS.md, or settings.json is backed up and left for you to merge — only the
# deterministic kit files are overwritten (and backed up first). jq is used for the settings
# merge IF present; otherwise the hooks block is printed for you to paste in.
set -eu

MODE=install
PI=auto   # auto | yes | no
for a in "$@"; do
  case "$a" in
    --update) MODE=update ;;
    --pi)     PI=yes ;;
    --no-pi)  PI=no ;;
  esac
done

KIT=$(cd "$(dirname "$0")" && pwd)
CLAUDE="${CLAUDE_HOME:-$HOME/.claude}"
WIKI="${PLAINBRAIN_WIKI:-$HOME/wiki}"
DATA="${PLAINBRAIN_DATA:-$HOME/data}"
PROJECTS="${PLAINBRAIN_PROJECTS:-$HOME/projects}"
NOTES="${PLAINBRAIN_NOTES:-$HOME/notes}"
BK="$CLAUDE/.plainbrain-backup/$(date +%Y%m%d-%H%M%S 2>/dev/null || echo backup)"
PIAGENT="$HOME/.pi/agent"   # Pi's native home (AGENTS.md, skills/, extensions/)

say()  { printf '%s\n' "$*"; }
note() { printf '  %s\n' "$*"; }

# Whether to wire the Pi harness target. --pi/--no-pi force it; otherwise auto-detect Pi.
pi_enabled() {
  case "$PI" in
    yes) return 0 ;;
    no)  return 1 ;;
    *)   command -v pi >/dev/null 2>&1 || [ -d "$HOME/.pi" ] ;;
  esac
}

# Back up a path (file or dir) into $BK, mirroring its location under $HOME.
backup() {
  [ -e "$1" ] || return 0
  rel=${1#"$HOME"/}; d=$BK/$(dirname "$rel")
  mkdir -p "$d"; cp -R "$1" "$d/"
  note "backed up $1"
}

# ---- kit-owned files (refreshed on both install and update) -----------------
install_kit() {
  mkdir -p "$CLAUDE/hooks" "$CLAUDE/skills"

  say "hooks ->"
  for h in "$KIT"/global/hooks/*.sh; do
    backup "$CLAUDE/hooks/$(basename "$h")"
    cp "$h" "$CLAUDE/hooks/"; chmod +x "$CLAUDE/hooks/$(basename "$h")"
    note "$(basename "$h")"
  done

  say "skills ->"
  for s in "$KIT"/global/skills/*/; do
    name=$(basename "$s")
    backup "$CLAUDE/skills/$name"
    rm -rf "$CLAUDE/skills/$name"; cp -R "$s" "$CLAUDE/skills/$name"
    note "$name"
  done

  # Pi target (kit-owned bits: per-skill symlinks + the lifecycle extension). Refreshed on
  # --update too. Symlink each skill (Pi resolves symlinks; a symlinked *root* trips a Pi
  # config display bug) at ~/.claude/skills/<name> — one copy serves both harnesses, and the
  # stable path survives this function's rm -rf/cp above. AGENTS.md placement is config, done
  # in first-time setup below (like opencode's).
  if pi_enabled; then
    say "pi skills + extension ->"
    mkdir -p "$PIAGENT/skills" "$PIAGENT/extensions"
    for s in "$KIT"/global/skills/*/; do   # only the kit's own skills, not the user's other ~/.claude/skills
      name=$(basename "$s")
      rm -rf "$PIAGENT/skills/$name"
      ln -s "$CLAUDE/skills/$name" "$PIAGENT/skills/$name"
    done
    rm -rf "$PIAGENT/extensions/plainbrain"; mkdir -p "$PIAGENT/extensions/plainbrain"
    cp "$KIT/global/pi/extensions/plainbrain/index.ts" "$PIAGENT/extensions/plainbrain/index.ts"
    note "skills symlinked + plainbrain extension -> $PIAGENT (invoke a skill as /skill:name)"
  fi

  say "project template ->"
  backup "$CLAUDE/project-template"
  rm -rf "$CLAUDE/project-template"; cp -R "$KIT/project-template" "$CLAUDE/project-template"

  say "plainbrain CLI ->"
  if printf '%s' ":$PATH:" | grep -q ":$HOME/.local/bin:" && [ -d "$HOME/.local/bin" ]; then
    cp "$KIT/global/bin/plainbrain" "$HOME/.local/bin/plainbrain"
    chmod +x "$HOME/.local/bin/plainbrain"
    note "installed to ~/.local/bin/plainbrain (on PATH)"
  else
    mkdir -p "$CLAUDE/bin"
    cp "$KIT/global/bin/plainbrain" "$CLAUDE/bin/plainbrain"; chmod +x "$CLAUDE/bin/plainbrain"
    note "installed to ~/.claude/bin/plainbrain — add ~/.claude/bin to your PATH"
  fi
}

install_kit

if [ "$MODE" = update ]; then
  say ""; say "update complete. Backups (if any) in $BK"
  exit 0
fi

# ---- first-time setup (install mode only) -----------------------------------
say "homes ->"
mkdir -p "$PROJECTS" "$DATA" "$NOTES"
mkdir -p "$WIKI"/entities "$WIKI"/concepts "$WIKI"/comparisons "$WIKI"/sources "$WIKI"/_lint
note "projects=$PROJECTS data=$DATA notes=$NOTES wiki=$WIKI"

# Wiki scaffold — only into an empty/new wiki; never overwrite an existing one.
if [ -z "$(ls -A "$WIKI"/*.md 2>/dev/null)" ]; then
  cp "$KIT"/wiki/*.md "$WIKI"/ 2>/dev/null || true
  [ -f "$KIT/wiki/entities/people.md" ] && cp "$KIT/wiki/entities/people.md" "$WIKI"/entities/ 2>/dev/null || true
  [ -f "$KIT/wiki/.gitignore" ] && cp "$KIT/wiki/.gitignore" "$WIKI"/ 2>/dev/null || true
  if [ ! -d "$WIKI/.git" ] && command -v git >/dev/null 2>&1; then
    ( cd "$WIKI" && git init -q && git add -A && git commit -q -m "init wiki" ) || true
  fi
  note "wiki scaffolded at $WIKI"
else
  note "wiki already populated at $WIKI — left as-is"
fi

# Global rules -> opencode's native global AGENTS.md (write if absent; else leave a .plainbrain-new to merge).
say "global rules ->"
OCODE="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
mkdir -p "$OCODE"
if [ ! -f "$OCODE/AGENTS.md" ]; then
  cp "$KIT/global/AGENTS.md" "$OCODE/AGENTS.md"
  note "installed to $OCODE/AGENTS.md"
else
  backup "$OCODE/AGENTS.md"
  cp "$KIT/global/AGENTS.md" "$OCODE/AGENTS.md.plainbrain-new"
  note "you already have one — kit copy saved as AGENTS.md.plainbrain-new; merge what you want"
fi
# Using Claude Code too? It reads only CLAUDE.md — copy this to ~/.claude/CLAUDE.md, or import it.

# Pi reads its own global AGENTS.md — same write-if-absent-else-.plainbrain-new logic.
if pi_enabled; then
  mkdir -p "$PIAGENT"
  if [ ! -f "$PIAGENT/AGENTS.md" ]; then
    cp "$KIT/global/AGENTS.md" "$PIAGENT/AGENTS.md"
    note "installed to $PIAGENT/AGENTS.md"
  else
    backup "$PIAGENT/AGENTS.md"
    cp "$KIT/global/AGENTS.md" "$PIAGENT/AGENTS.md.plainbrain-new"
    note "you already have one — kit copy saved as AGENTS.md.plainbrain-new; merge what you want"
  fi
fi

# settings.json hooks block — merge non-destructively.
say "settings.json hooks ->"
SET="$CLAUDE/settings.json"
if [ ! -f "$SET" ]; then
  cp "$KIT/global/settings.json" "$SET"
  note "installed"
elif grep -q 'gate\.sh' "$SET" 2>/dev/null; then
  note "hooks already wired — skipped"
elif command -v jq >/dev/null 2>&1; then
  # Merge per event, skipping any kit entry whose script is already wired under that event
  # (matched by filename — user copies may use absolute paths or different timeouts). An
  # older install gains the new events without duplicating the ones it already has.
  backup "$SET"
  jq --slurpfile k "$KIT/global/settings.json" '
    .hooks = ((.hooks // {}) as $h | $k[0].hooks as $kh
      | reduce ($kh | keys[]) as $e ($h;
          .[$e] = ((.[$e] // []) + ($kh[$e] | map(select(
            (.hooks[0].command | split("/") | last) as $s
            | ((($h[$e] // []) | tojson | contains($s))) | not )))) ))
  ' "$SET" > "$SET.tmp" && mv "$SET.tmp" "$SET"
  note "merged the hooks block via jq (existing entries kept)"
else
  note "no jq — add the \"hooks\" block from $KIT/global/settings.json to $SET yourself"
fi

# Env file + source-line instruction (never edits your shell rc automatically).
say "homes config ->"
mkdir -p "$HOME/.config/plainbrain"
if [ ! -f "$HOME/.config/plainbrain/env" ]; then
  cp "$KIT/plainbrain.env.example" "$HOME/.config/plainbrain/env"
  note "wrote ~/.config/plainbrain/env (defaults) — edit it to relocate any home"
else
  note "~/.config/plainbrain/env already exists — left as-is"
fi
note "to apply overrides, add to your shell rc: [ -f ~/.config/plainbrain/env ] && . ~/.config/plainbrain/env"

say ""
say "install complete. Backups (if any) in $BK"
say "Next: open a repo in your agent (Claude Code / Pi / opencode) and run \"adopt this project\" to activate it."
