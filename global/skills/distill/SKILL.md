---
name: distill
description: Distill a work session into durable memory — the deliberate end-of-session sweep. decisions.md and the driver are kept current as you work; distill catches what only surfaces at the end: wiki-worthy knowledge, new or repaired skills, standing facts about you. Proposes a short candidate list for approval, routes each to its home, then commits. Run when wrapping up a session, or after resolving a decision; also reconciles any decision or plan change not yet written.
---

# distill

Invoked with no arguments. You propose; the user approves; only then do you write.
**The user is the noise gate** — your job is a short, honest candidate list.

decisions.md and the driver (plan.md / CONTEXT.md) are written *continuously*, as the work
happens — they are not what this skill is for. distill is the deliberate end-of-session
**sweep**: the things that only surface when you step back — durable knowledge worth a wiki
page, a repeatable procedure worth a skill, a standing fact about the user — plus a reconcile
of anything that *should* have been logged inline but wasn't, then one clean commit.

0. **Pre-check.** Run `~/.claude/skills/distill/check.sh`. On `SAVED` or `CLEAN`, still
   scan the conversation for any durable item NOT already in the files (the wiki / skill /
   me.md sweep, step 2) — if there is none, report "nothing to distill" citing the commits
   from the check output, write the marker (step 6), and STOP. Read nothing else.
   On `UNSAVED` or `COMMITS-NO-DURABLES`, continue with the full skill.
   Either way, if `.claude/state/decisions.scratch` exists, read it — parked *why* lines not
   yet in `decisions.md` are themselves something to distill (reconcile them in step 2).

1. **Locate the project.** `git rev-parse --show-toplevel`. Read the project's CLAUDE.md
   pointer block: it declares which durable files this project carries (core: decisions.md;
   modules: plan.md, CONTEXT.md, ARCHITECTURE.md) and which one is the driver. Read the
   declared files. Route ONLY to declared files — never create a missing module (no plan.md
   in a project that doesn't plan). If a missing module seems genuinely needed, suggest
   re-running adopt-project instead.

2. **Extract candidates — reconcile, then sweep.** Review the conversation,
   `.claude/state/decisions.scratch` (parked rationale that a compaction may have dropped from
   the conversation — treat each line as a reconcile candidate), plus `git status` / `git diff`.
   First **reconcile**: a decision made or inconsistency resolved that never reached
   `decisions.md`, or plan movement not yet in the driver — propose it now (grep decisions.md
   first; already recorded means don't re-propose). Rare if you logged as you worked. Also surface **abandoned approaches**: something tried that hit a surprising failure or dead end and was dropped — "tried X, got Y, went with Z" — so the next session doesn't re-derive it; route to decisions.md, or a wiki page if it's a cross-project gotcha.
   Then the **sweep** — the candidates that only surface at session end (what to look for;
   destinations and write-rules are all in step 3):
   - **wiki:** knowledge that is durable (true in 6+ months), cross-project, about the world
     (not this repo's internals), and cost real effort to learn (full litmus in
     `$PLAINBRAIN_WIKI/CLAUDE.md`). Facts go to the wiki; procedures become skills.
   - **skill — capture:** a repeatable procedure that would cost the next session real time to
     re-derive. Signals: a multi-step sequence that worked only after iteration; a non-obvious
     gotcha you found the workaround for; a convention or recipe the user will reuse; the user
     said "remember how to do this."
   - **skill — repair:** an existing skill that misfired or showed stale instructions this session.
   - **me.md:** a standing fact about the user as a person, useful beyond this project.
   Most sessions produce no sweep candidates — that's the expected answer.

3. **Propose, then WAIT for approval.** Present the candidates (typically 0–3) as a short
   list, each with its destination:
   - decision / resolved inconsistency → timestamped one-liner appended at the very END of
     `decisions.md` — newest entry is always the last line, never inserted mid-file
     (`YYYY-MM-DD HH:MM: changed X because Y`); cite the enacting commit short-hash or wip ref when the decision maps to a specific change. If it reverses a prior decision, end the line with `— supersedes <YYYY-MM-DD HH:MM>` naming the overridden entry (which stays; never edit or delete it). Timestamps come from
     `date '+%Y-%m-%d %H:%M'` — always run the command; never stamp from model memory.
   - plan progressed or changed → the relevant **volatile subsection** of `plan.md`;
     stable-section changes flagged loudly and shown in full
   - standing knowledge for THIS project (direction, taste, constraints) → `CONTEXT.md`
   - new architectural fact → `ARCHITECTURE.md`
   - fact about the user as a person, useful beyond this project → `$PLAINBRAIN_WIKI/entities/me.md`
   - cross-project world-fact passing the wiki litmus → a page in `$PLAINBRAIN_WIKI`, filed
     directly (update index.md; commit noting "filed from session"); full
     wiki-ingest only when a real source file exists in `$PLAINBRAIN_DATA` or `$PLAINBRAIN_NOTES`
   - repeatable procedure (capture) or skill misfire (repair) → a SKILL.md draft (project-bound
     → `.claude/skills/` in the repo; cross-project → `~/.claude/skills/`) or minimal fix, shown
     in full before writing (a SKILL.md is born only on approval)
   - off-project or unformed → a stub note in `$PLAINBRAIN_NOTES` (inbox), for later routing
   - project CLAUDE.md contradicts reality → flag it in the list; never edit CLAUDE.md here
   **If nothing durable changed, say so and stop.** Do not invent entries to look productive.

4. **Write exactly what was approved** — nothing more. **Bias to additive:** a new small page or an appended section beats rewriting an existing page's body; a body-rewrite of standing content needs a strong reason and usually loses to a new page (the diff stays legible, nothing is silently overwritten). decisions.md is append-only; plan.md's *volatile* subsections are the deliberate exception.

5. **Commit** with a clear message summarizing the session's real work. A clean distill MUST
   leave NO project repo dirty — otherwise the exit hook snapshots the leftover and re-raises
   `.pending-distill`, contradicting the sweep you just made.

6. **Write the marker** (and clear the rationale scratch — its lines are now reconciled into
   `decisions.md`, or were reviewed and dropped):
   ```
   mkdir -p .claude/state
   date +%s > .claude/state/.last-distill
   rm -f .claude/state/.pending-distill .claude/state/decisions.scratch
   ```

Preserve the *why*, not just the *what* — git already has the what. When a record has a fuller trace — the enacting commit, the wip ref, the session transcript — *point* at it; never paste a trace into the file or the context: a pointer keeps the log lean and the raw record one hop away.
