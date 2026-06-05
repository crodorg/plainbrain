# Global rules (~/.claude/CLAUDE.md)

Loaded into every Claude Code session. Keep this short — every line is paid on every message.

## Role
You produce the code; I supervise and approve. Don't write or change code without an agreed
plan. For any non-trivial task, propose the plan first and wait for my go-ahead.

## Project discipline
- Every project carries `decisions.md` (append-only "what + why") plus the modules that fit:
  `plan.md` (phased execution), `CONTEXT.md` (standing knowledge), `ARCHITECTURE.md` (codebase
  map). Its CLAUDE.md names the **driver** — plan.md or CONTEXT.md.
- Read the driver before working. Drivers have **stable sections** (rarely change) and
  **volatile subsections** (change during execution).
- When you hit an inconsistency mid-task, do NOT silently rewrite the plan. Record it in
  `decisions.md` (`YYYY-MM-DD HH:MM: changed X because Y`, appended at the very end) and
  adjust the relevant subsection deliberately.
- decisions.md is the audit trail, not the state — current state lives in the driver; the log
  holds the why. Code is the source of truth; the driver states intent; git is the proof.

## Git
- Commit at logical checkpoints with real messages. Branch for anything risky or exploratory.
- Hooks auto-snapshot WIP (pre-compact and on exit) — those are safety nets, not curated history.
- Never force-push; never rewrite shared history without asking.

## Where things live
- `~/projects/<name>` — each its own repo: CLAUDE.md + decisions.md + the modules that fit
- `~/wiki` — the knowledge wiki (compiled, interlinked markdown; query it first)
- `~/wiki/entities/me.md` — the user's standing philosophy, taste, voice. Read it before
  creative choices, drafting, or preference-sensitive work — don't guess.
- `~/data` — raw reference material (read-only sources; not a git repo)
- `~/notes` — my personal notes (a source the wiki can index)

## Skills
- `save-context` — propose the session's durable items for approval, persist, then commit.
- `adopt-project` — bring a new or existing project into this layout (once per project).
- `wiki-ingest` / `wiki-query` / `wiki-lint` — build and use the knowledge wiki.

## Communication
TLDR first. Direct and concise. Minimal formatting. Push back honestly; don't pad.
Keep every CLAUDE.md (this one and per-project) lean.
