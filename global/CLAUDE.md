# Global rules (~/.claude/CLAUDE.md)

Loaded into every Claude Code session. Keep this short — every line is paid on every
message. These are the plainbrain conventions — merge what you like into your own
global rules; the project-discipline section is the load-bearing part.

## Project discipline
- Every project carries `decisions.md` (append-only "what + why") plus the modules that fit:
  `plan.md` (phased execution), `CONTEXT.md` (standing knowledge), `ARCHITECTURE.md` (codebase
  map). Its CLAUDE.md names the **driver** — plan.md or CONTEXT.md.
- Read the driver before working. Drivers have **stable sections** (rarely change) and
  **volatile subsections** (change during execution).
- When you hit an inconsistency mid-task, do NOT silently rewrite the plan. Record it in
  `decisions.md` (`YYYY-MM-DD HH:MM: changed X because Y`, appended at the very end; stamp
  via `date '+%Y-%m-%d %H:%M'`, never from memory) and adjust the relevant subsection
  deliberately.
- Park a decision's *why* in `.claude/state/decisions.scratch` (ephemeral, gitignored) the
  moment you make it — one line each, no approval needed. It survives a context compaction
  that would otherwise drop the reasoning; distill reconciles the scratch into `decisions.md`
  on approval, then clears it.
- decisions.md is the audit trail, not the state — current state lives in the driver; the log
  holds the why. Code is the source of truth; the driver states intent; git is the proof.

## Git
- Commit at logical checkpoints with real messages. Branch for anything risky or exploratory.
- In a repo you've adopted (it carries a `.claude/plainbrain` marker), the hooks snapshot WIP to a
  private ref (`refs/plainbrain/wip/<session>`, recoverable with the `plainbrain` CLI) — never a
  branch commit. Un-adopted repos are left untouched. These snapshots are safety nets, not history.
- Never force-push; never rewrite shared history without asking.

## Where things live
Homes honor `$PLAINBRAIN_*` env vars (set in `~/.config/plainbrain/env`); defaults shown.
- `$PLAINBRAIN_PROJECTS` (default `~/projects`)`/<name>` — each its own repo: CLAUDE.md + decisions.md + the modules that fit
- `$PLAINBRAIN_WIKI` (default `~/wiki`) — the knowledge wiki (compiled, interlinked markdown; query it first)
- `$PLAINBRAIN_WIKI/entities/me.md` — the user's standing philosophy, taste, voice. Read it before
  creative choices, drafting, or preference-sensitive work — don't guess.
- `$PLAINBRAIN_DATA` (default `~/data`) — raw reference material (read-only sources; not a git repo)
- `$PLAINBRAIN_NOTES` (default `~/notes`) — the user's own notes (a source the wiki can ingest)

## Skills
- `adopt-project` — bring a new or existing project into this layout and activate it (once per project).
- `distill` — the end-of-session sweep: propose durable wiki/skill/me.md items for approval, then
  commit (decisions.md + the driver stay current as you work).
- `wiki-ingest` / `wiki-query` / `wiki-lint` — build and use the knowledge wiki.

## Grounding
- Cite factual claims: `file:line`, wiki page, or URL — never cite anything not actually
  read/fetched this conversation. Tag unsourced claims as unverified.
- Durable findings worth keeping → offer the wiki so next time the answer is local and cited.

Keep every CLAUDE.md (this one and per-project) lean.
