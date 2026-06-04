---
name: save-context
description: Persist the meaningful state of the current Claude Code session into the project's durable files. Run at the end of a work session, before /exit, or whenever a decision or inconsistency has been resolved. Reads the project layout and routes each kind of information to its correct home, then commits.
---

# save-context

Invoked with no arguments. Be conservative — preserve signal, ignore noise.

1. **Locate the project.** `git rev-parse --show-toplevel`. Read `plan.md`, `decisions.md`,
   and `ARCHITECTURE.md` if they exist.

2. **Review what actually happened this session.** Look at `git status` and `git diff`, plus
   the conversation. Identify only *durable* facts:
   - decisions made
   - inconsistencies found and how they were resolved
   - structural / architectural changes
   - external model opinions (Grok, Gemini) worth keeping

3. **Route each item to its home:**
   - decision or resolved inconsistency -> append a timestamped one-liner at the very END of
     `decisions.md` — newest entry is always the last line, never inserted mid-file
     (`YYYY-MM-DD HH:MM: changed X because Y`); if the plan itself changed, update the relevant
     **subsection** of `plan.md`. Never silently rewrite a stable section — if a stable
     section must change, propose it and get the user's OK BEFORE writing it.
   - new architectural fact -> update `ARCHITECTURE.md`
   - external opinion worth keeping -> `decisions.md`
   - reference material -> note its location under `~/data/`; do not commit large files
   - cross-project insight (useful beyond this project) -> promote it into `~/wiki` with the
     wiki-ingest skill, or jot a stub in `~/notes` for later ingest
   - the project's `CLAUDE.md` contradicts the new reality -> flag it in your summary;
     never edit CLAUDE.md from this skill

4. **If nothing durable changed, say so and stop.** Do not invent entries to look productive.

5. **Commit.** Stage and commit with a clear message summarizing the session's real work.

6. **Write the marker:**
   ```
   mkdir -p .claude/state
   date +%s > .claude/state/.last-save
   rm -f .claude/state/.pending-save
   ```

Prefer append-only edits. Preserve the *why*, not just the *what* — git already has the what.
