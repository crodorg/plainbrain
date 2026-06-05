# USAGE — operating plainbrain day to day

The README explains why; this explains how, with worked examples. The system runs on two
lifecycle commands plus a handful of on-demand verbs — everything else is hooks.

## The one question: where does this go?

Everything durable that crosses your desk fits one of four homes:

| You have... | It goes to... | How it gets there |
|---|---|---|
| Decided to use LISTEN/NOTIFY instead of Redis | `<project>/decisions.md` | "save context" at session end |
| A competitor's Q1 earnings PDF | `~/data/<project>/`, then the wiki | `cp` it there; "ingest ~/data/acme/q1.pdf" |
| Learned a durable fact about a company/tool | `~/wiki/entities/` | falls out of an ingest, or "file this into the wiki" |
| A shower thought | `~/notes` | however you capture notes |
| "Which vendors did we rule out, and why?" | answered FROM the wiki | "query the wiki: …" |
| An outside model's take that changed your mind | `decisions.md` | save-context keeps opinions that mattered |
| How the deploy pipeline works | `<project>/ARCHITECTURE.md` | save-context routes structural facts |
| A durable X-vs-Y analysis | `~/wiki/comparisons/` | wiki-query offers to file it back — say yes |
| A standing fact about yourself ("I hate X in a mix") | `~/wiki/entities/me.md` | save-context proposes it |

Routing rules of thumb:
- **About one project's direction** → that project's `decisions.md` / driver (`plan.md` or `CONTEXT.md`)
- **About you as a person, beyond one project** → `~/wiki/entities/me.md`
- **Fact about the world, useful across projects** → wiki
- **Fleeting / personal / unformed** → notes, promoted later
- **Raw artifact** → `~/data/<project>/`, ingested when it earns it

## Automatic vs. manual

| Automatic (hooks, every session) | Manual (you trigger) |
|---|---|
| Session start: recent git log + "read the driver" injected | "save context" at session end |
| Pre-compact: `wip:` commit — compaction can't lose work | "ingest <path>", "query the wiki", "lint the wiki" |
| Session end: `wip:` rescue commit + reminder flag | notes capture, wiki-save / notes-save aliases |
| Next session start: lists unsaved wip commits, asks what to do | "adopt this project" (once per project) |

The marker handshake (`.claude/state/`): saving context writes `.last-save` and clears the
flag. Exiting *without* saving sets `.pending-save`; the next session start lists every commit
since the last save and asks: **distill / keep accumulating / discard**. Lazy is recoverable.

## Loop 1 — a project work session

```
$ cd ~/projects/myapp && claude
  # hooks inject: last 5 commits + pointer to plan.md — Claude starts oriented

> continue phase 2, the queue worker
  # ...work happens. Mid-session you switch from Redis to LISTEN/NOTIFY. Say so.

> save context
  # → proposes 0–3 durable items with destinations; YOU approve — you are the noise gate
  # → decisions.md += "2026-06-11 18:02: dropped Redis for LISTEN/NOTIFY — one less daemon"
  # → plan.md phase status updated; ARCHITECTURE.md updated if structure changed
  # → commit with a real message
```

Close the laptop without saving? A `wip:` commit lands and the next session opens by asking
about it. Some projects never need saving at all — if the files ARE the context (dotfiles,
configs), the wip commits are already the perfect log.

## Loop 2 — feeding the wiki

```
$ cp ~/Downloads/acme-q1-2026.pdf ~/data/acme/
# in any Claude session:
> ingest ~/data/acme/acme-q1-2026.pdf into the wiki
```

What happens, in order: Claude reads it, **discusses takeaways with you first**, greps the
wiki to edit-rather-than-duplicate, then writes a `sources/` summary (citing the raw path),
updates entity/concept pages with cross-links both directions, flags dated contradictions
with existing claims, updates `index.md` + `log.md`, commits. One source touching 10–15
pages is normal. Raw files in `~/data` are never modified.

## Loop 3 — asking the wiki

**The lookup.** "query the wiki: who's the CFO at Acme?" → index → one page → cited answer.

**The synthesis (the compounding move).** "query the wiki: compare vendor A vs vendor B for
us" → Claude pulls the relevant pages, builds the comparison, then **offers to file it back**
as `comparisons/a-vs-b.md`. Say yes. Next month that analysis is a first-class page other
queries can cite — explorations stop dying in chat history.

**The contradiction.** A query that finds two pages disagreeing surfaces both, dated, instead
of silently picking one. You resolve it when you actually know.

Habit: **ask the wiki before asking the internet.**

## Loop 4 — notes

Capture however you like — any tool that writes markdown into `~/notes` works. Promote a
note that matured into real knowledge: "ingest ~/notes/that-idea.md into the wiki". Notes
are a first-class source, same as `~/data`.

## Cadence

| When | What |
|---|---|
| End of every work session | "save context" (or trust the wip safety net) |
| Before a manual `/compact` in a decision-heavy session | "save context" first — hooks snapshot files, not conversation |
| Material arrives | drop in `~/data/<project>/`; ingest when it earns it |
| Weekly-ish | commit your notes (`notes-save`) |
| Monthly-ish, or after hand-editing the wiki | "lint the wiki", then `wiki-save` |
| Never | cron. Everything is triggered; nothing runs behind your back. |

## When things go wrong

| Went wrong | The system already did | You do |
|---|---|---|
| Exited without saving | `wip:` commit + flag | next session asks; pick distill |
| Compaction mid-task | pre-compact `wip:` commit | nothing — keep working |
| Hand-edited wiki, links stale | nothing (your edits are yours) | "lint the wiki" reconciles |
| "When did we decide X?" | decisions.md is append-only + timestamped | grep it |
| Wiki page contradicts a new source | ingest flagged + dated it | resolve when you know |
| Want a mechanical wiki health check | — | `sh ~/.claude/skills/wiki-lint/wiki-check.sh` |

## Anti-patterns — the ways this rots

- **Pasting a 30-page doc into chat** and hoping it's remembered. `~/data` + ingest is the path.
- **Editing files in `~/data`.** Read-only corpus; wiki pages cite into it.
- **Crossing the streams.** Project state in the wiki, or world-facts buried in one project's
  decisions.md — both make retrieval rot. Route by the table above.
- **Skipping the file-back offer** after a good query. That offer IS the compounding mechanism.
- **`[[wikilinks]]`.** Relative markdown links only — they survive any renderer.
- **Giant wiki pages.** One concept per file; split past ~150 lines.
- **Deep folder taxonomies.** Items belong to multiple categories; links + tags + the index
  carry structure. Directories stay shallow.
