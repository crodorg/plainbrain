# Global rules (~/.claude/CLAUDE.md)

Loaded into every Claude Code session. Keep this short — every line is paid on every message.

## Role
You produce the code; I supervise and approve. Don't write or change code without an agreed
plan. For any non-trivial task, propose the plan first and wait for my go-ahead.

## Plan discipline
- Each project has a `plan.md` (the driver) and a `decisions.md` (append-only "what + why").
- Read `plan.md` before working. Plans have **stable sections** (rarely change) and **volatile
  subsections** (change during execution).
- When you hit an inconsistency mid-task, do NOT silently rewrite the plan. Record it in
  `decisions.md` (`YYYY-MM-DD HH:MM: changed X because Y`, appended at the very end) and
  adjust the relevant subsection deliberately.
- Code is the source of truth; the plan states intent; git is the proof.

## Git
- Commit at logical checkpoints with real messages. Branch for anything risky or exploratory.
- Hooks auto-snapshot WIP (pre-compact and on exit) — those are safety nets, not curated history.
- Never force-push; never rewrite shared history without asking.

## Where things live
- `~/projects/<name>` — code; each its own repo with CLAUDE.md, plan.md, decisions.md, ARCHITECTURE.md
- `~/wiki` — the knowledge wiki (compiled, interlinked markdown; query it first)
- `~/data` — raw reference material (read-only sources; not a git repo)
- `~/notes` — my personal notes (a source the wiki can index)

## Skills
- `adopt-project` — bring a new or existing project into this layout (once per project).
- `save-context` — persist the current project session into plan.md/decisions.md, then commit.
- `wiki-ingest` / `wiki-query` / `wiki-lint` — build and use the knowledge wiki.

## Communication
TLDR first. Direct and concise. Minimal formatting. Push back honestly; don't pad.
Keep every CLAUDE.md (this one and per-project) lean.
