# plainbrain

A memory and knowledge system for AI coding agents — plain markdown, git, and a few POSIX
shell scripts. This repo is the distributable kit (and its own audit trail).

## Pointers
<!-- core-only project: no plan.md/CONTEXT.md driver. The README is the map; decisions.md is the why. -->
- Overview / design thesis: `./README.md` — read it first
- Decision log: `./decisions.md` — append-only, newest last: what changed and why
- The kit itself:
  - `global/` — hooks, skills, the shipped global rules, the `plainbrain` CLI
  - `project-template/` — the core + module templates copied into adopted projects
  - `wiki/` — the wiki scaffold
  - `install.sh` / `update.sh` — idempotent, backup-first installer + kit updater

## Project rules
- POSIX sh, no hard deps; the installer is idempotent and backup-first — never clobber a
  user's data or merged config.
- The kit dogfoods its own layout: this file is the AGENTS.md every adopted project carries.
- Keep the substrate dumb (markdown, shell, git); the intelligence is rented at runtime.

Global rules apply (see `~/.config/opencode/AGENTS.md`). Keep this file lean.
