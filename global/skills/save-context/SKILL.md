---
name: save-context
description: Persist the meaningful state of the current Claude Code session into the project's durable files. Run at the end of a work session, before /exit, or whenever a decision or inconsistency has been resolved. Proposes a short list of durable items for approval, routes each to its declared home, then commits.
---

# save-context

Invoked with no arguments. You propose; the user approves; only then do you write.
**The user is the noise gate** — your job is a short, honest candidate list.

0. **Pre-check.** Run `~/.claude/skills/save-context/check.sh`. On `SAVED` or `CLEAN`,
   scan the conversation for any durable item NOT already in the files (including wiki
   candidates, step 2) — if there is none, report "already saved" citing the commits
   from the check output, write the marker (step 6), and STOP. Read nothing else.
   On `UNSAVED` or `COMMITS-NO-DURABLES`, continue with the full skill.

1. **Locate the project.** `git rev-parse --show-toplevel`. Read the project's CLAUDE.md
   pointer block: it declares which durable files this project carries (core: decisions.md;
   modules: plan.md, CONTEXT.md, ARCHITECTURE.md) and which one is the driver. Read the
   declared files. Route ONLY to declared files — never create a missing module (no plan.md
   in a project that doesn't plan). If a missing module seems genuinely needed, suggest
   re-running adopt-project instead.

2. **Extract candidates.** Review the conversation plus `git status` / `git diff`. Strictly
   durable items only — things a future session would fail or redo work without: decisions
   made, inconsistencies resolved, structural changes, outside opinions that changed a
   decision. Before proposing a decisions.md entry, grep decisions.md — already recorded
   means don't re-propose.
   Then a **wiki sweep**: did the session produce knowledge that is durable (true in 6+
   months), cross-project, about the world (not this repo's internals), and cost real
   effort to learn? Propose it as a wiki candidate naming the target page (full litmus
   in `~/wiki/CLAUDE.md`). Most sessions produce none — that's the expected answer.

3. **Propose, then WAIT for approval.** Present the candidates (typically 0–3) as a short
   list, each with its destination:
   - decision / resolved inconsistency → timestamped one-liner appended at the very END of
     `decisions.md` — newest entry is always the last line, never inserted mid-file
     (`YYYY-MM-DD HH:MM: changed X because Y`; stamp from the system clock, never from memory)
   - plan progressed or changed → the relevant **volatile subsection** of `plan.md`;
     stable-section changes flagged loudly and shown in full
   - standing knowledge for THIS project (direction, taste, constraints) → `CONTEXT.md`
   - new architectural fact → `ARCHITECTURE.md`
   - fact about the user as a person, useful beyond this project → `~/wiki/entities/me.md`
   - cross-project world-fact passing the wiki litmus → a page in `~/wiki`, filed
     directly (update index.md; log.md entry noting "filed from session"); full
     wiki-ingest only when a real source file exists in `~/data` or `~/notes`
   - off-project or unformed → a stub note in `~/notes` (inbox), for later routing
   - project CLAUDE.md contradicts reality → flag it in the list; never edit CLAUDE.md here
   **If nothing durable changed, say so and stop.** Do not invent entries to look productive.

4. **Write exactly what was approved** — nothing more. Prefer append-only edits.

5. **Commit** with a clear message summarizing the session's real work.

6. **Write the marker:**
   ```
   mkdir -p .claude/state
   date +%s > .claude/state/.last-save
   rm -f .claude/state/.pending-save
   ```

Preserve the *why*, not just the *what* — git already has the what.
