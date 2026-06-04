# plainbrain

**Plain files, whole brain.** A memory and knowledge system for [Claude Code](https://claude.com/claude-code) built from markdown, git, and three small shell scripts. No database, no daemons, no vector store, no subscriptions — and your AI stops forgetting what matters.

## The problem

Every AI coding session starts with amnesia. You re-explain your project, re-justify decisions you made weeks ago, re-paste the same context. Built-in memory features help, but they write to opaque files behind your back — you can't easily see what the model "knows" about you, audit it, or fix it when it's wrong. And when the context window fills up and gets compacted, nuance quietly dies.

Meanwhile, the actual knowledge you accumulate — research, comparisons, hard-won conclusions — evaporates into chat history you'll never scroll back through.

## The idea in 60 seconds

Turn implicit memory into **three explicit memories, each a plain file you can read**:

```
conversation ──"save context"──▶  <project>/plan.md + decisions.md    (project state)
raw documents ──drop──────────▶  ~/data/<project>/   (no git)  ──┐
quick thoughts ──capture──────▶  ~/notes/            (git)      ──┤──"ingest"──▶  ~/wiki
questions ──"query the wiki"──▶  cited answer ──filed back──────────────────────▶  (git)
```

1. **Project state** — every repo carries `plan.md` (intent), `decisions.md` (append-only log of *what changed and why*, timestamped), and `ARCHITECTURE.md` (codebase map). The AI reads them at session start and updates them at session end.
2. **Knowledge** — `~/wiki`: small, single-topic markdown pages (entities, concepts, comparisons, sources) cross-linked with relative links and cataloged in one `index.md`. The AI does the bookkeeping; you supervise.
3. **Inbox** — `~/notes`: your own notes, a first-class source the wiki can ingest.

Three hooks make git self-maintaining: session start injects recent git history and a pointer to the plan; before context compaction a `wip:` commit snapshots everything; on exit, unsaved work gets rescued into a `wip:` commit and the next session opens by asking what to do with it. **Forgetting to save is always recoverable.**

The day-to-day surface is two commands: *adopt a project once, save context at the end of sessions.* Everything else is automatic (hooks) or on-demand (ask the wiki, ingest a document).

## Dumb and smart at the same time

This is the design thesis, and the reason the system should still work years from now.

**The substrate is deliberately dumb.** Markdown files. POSIX shell. Git. An "index" that is literally a list of links. A validator that is 60 lines of grep. There is nothing to install, migrate, host, or debug at 2am. Every single thing the AI "remembers" is a line in a file you can read, grep, hand-edit, and `git diff`. When the AI is wrong about something, you can see exactly where and fix it with a text editor.

**The smart layer is rented at runtime.** The skills — ingest, query, lint, save-context, adopt-project — are plain-English instruction files the model reads when invoked. The intelligence (what matters, what contradicts what, where a fact belongs, what to cross-link) is applied fresh by whatever model you run, with judgment, in conversation with you. When models get smarter, this whole system gets smarter, with zero code changes.

Dumb substrate, smart runtime. Systems built the other way around — smart substrate (embeddings, schemas, agents-with-state) — rot when their runtime assumptions change. Files don't rot.

## What's in the box

| Path | What it is |
|---|---|
| `global/hooks/` | 3 hooks: session-start (inject git state + plan pointer + unsaved-work triage), pre-compact (wip snapshot), session-end (wip rescue + reminder flag) |
| `global/skills/adopt-project/` | Bring any project — new or existing — into the layout: interview + drafted files, approved before written |
| `global/skills/save-context/` | End-of-session distiller: routes durable facts into plan / decisions / architecture, commits |
| `global/skills/wiki-ingest/` | Source → wiki: summary page, entity/concept updates, cross-links, contradiction flags, index + log |
| `global/skills/wiki-query/` | Index-first retrieval, cited answers, offers to file durable answers back as new pages |
| `global/skills/wiki-lint/` | Health check: deterministic `wiki-check.sh` pre-pass (dead links, index drift, orphans) + semantic review |
| `global/skills/grok\|gemini\|perspectives/` | Optional: one-shot second opinions from outside models via OpenRouter — they advise, Claude executes |
| `global/CLAUDE.md` | Lean global rules: plan discipline, git discipline, where things live |
| `global/settings.json` | The hook wiring (merge into yours — don't overwrite) |
| `wiki/` | Wiki scaffold: schema doc, index, log, overview |
| `project-template/` | The four files every project carries |

## Install (5 minutes, manual on purpose)

Requirements: Claude Code, git, bash. (`jq` + `curl` + an `OPENROUTER_API_KEY` only if you want the optional perspective skills.)

```sh
git clone https://github.com/crodorg/plainbrain
cd plainbrain

# 1. hooks
mkdir -p ~/.claude/hooks
cp global/hooks/*.sh ~/.claude/hooks/ && chmod +x ~/.claude/hooks/*.sh

# 2. settings — MERGE, don't overwrite. If you already have hooks in
#    ~/.claude/settings.json, add these entries alongside yours.
#    (Already have a SessionStart hook? Install ours under a different
#    filename, e.g. session-start-git.sh, and register it as a second entry —
#    hooks stack additively.)
cat global/settings.json   # then merge by hand or let Claude do it

# 3. skills
cp -r global/skills/* ~/.claude/skills/

# 4. global rules — read global/CLAUDE.md and merge what you like into
#    ~/.claude/CLAUDE.md. The plan-discipline section is the load-bearing part.

# 5. the four homes
mkdir -p ~/projects ~/data ~/notes
cp -r wiki ~/wiki
mkdir -p ~/wiki/{entities,concepts,comparisons,sources,_lint}
git -C ~/wiki init && git -C ~/wiki add -A && git -C ~/wiki commit -m "init wiki"
```

Optional shell aliases for the two repos nothing auto-commits:

```sh
alias wiki-save='git -C ~/wiki add -A && git -C ~/wiki commit -m "wiki: $(date -u +%FT%TZ)"'
alias notes-save='git -C ~/notes add -A && git -C ~/notes commit -m "notes: $(date -u +%FT%TZ)"'
```

Verify: open Claude Code in any git repo and check the injected "Session context" block (Ctrl+O shows hook output), or look for `.claude/state/.session-start`.

## Daily use

| When | You do |
|---|---|
| Project's first contact (new or existing) | "adopt this project" — once, ever |
| End of a work session | "save context" — the one habit |
| A document worth keeping arrives | drop it in `~/data/<project>/`, then "ingest this into the wiki" |
| You need something you once knew | "query the wiki: …" — answer comes back with file citations |
| A passing thought | capture to `~/notes` however you like; promote to the wiki later |
| Monthly-ish | "lint the wiki" — contradictions, dead links, orphans |

And what you *don't* do: you never manually log what happened (hooks commit snapshots with timestamps), never organize the wiki by hand (ingest does the filing, lint does the auditing), and never lose work to a crashed or forgotten session (wip commits + next-session triage).

## What's actually different here

Compared to the obvious alternatives:

- **vs. built-in auto-memory** — Everything is explicit, inspectable, and versioned. Memory is *routed by kind* — project state, world knowledge, personal notes go to different homes with different lifecycles — instead of one opaque bucket. Nothing is written behind your back; `git log` is the audit trail.
- **vs. vector databases / RAG** — Retrieval is an index file plus links the model follows, like a human using a wiki. Cost scales with the index and the pages actually read — not with corpus size. No embeddings to drift, no re-indexing, no similarity scores to tune, and citations are file paths you can open.
- **vs. Obsidian/Notion second brains** — Those are for humans to maintain; this is **co-maintained**: the AI does the tedious part (filing, cross-linking, index updates, contradiction flagging) and you do the judgment part (what matters, what's true). The maintenance burden that kills most second brains is precisely the part that's delegated.
- **vs. agent-memory frameworks (MemGPT-style)** — No server, no runtime, no schema. The "framework" is conventions written in markdown. It works offline, survives tool churn, and every component is replaceable with `sed`.

Smaller novelties worth stealing even if you don't adopt the whole system:

- **The contradiction ledger.** Wiki pages have a dated "Open questions / contradictions" section. New facts that conflict with old ones get *recorded as disagreement*, never silently overwritten. Your knowledge base admits uncertainty.
- **The append-only decisions file.** One timestamped line per decision: `2026-06-04 16:45: chose X because Y`. Six months later, "why on earth did we do it this way?" is a grep, not an archaeology dig.
- **wip-commit safety nets.** Context compaction and session exits trigger deterministic snapshot commits. The next session lists them and asks: distill, keep, or discard. Laziness is a recoverable state.
- **Deterministic verification.** `wiki-check.sh` proves the wiki's structural health (dead links, index drift, orphans) with zero AI involvement. Trust, but grep.

## Who this is for

**A good fit if you:** live in Claude Code across multiple projects; want to *audit* what your AI remembers; accumulate research/decisions that deserve to outlive chat history; like plain text and git; work across machines (everything syncs as ordinary repos).

**A bad fit if you:** want fully-automatic zero-habit memory (this asks for one habit: "save context"); need true team-concurrent editing of shared knowledge (git merges of prose are mediocre); have a corpus so large it genuinely needs semantic search (see below).

## Expanding it

The dumb substrate makes extensions easy bolt-ons rather than migrations:

- **Semantic search** — when `index.md` outgrows grep, add an embedding index *next to* the files. The files stay canonical; the index is disposable.
- **Scheduled lint** — the system is deliberately cron-free (nothing runs behind your back), but `wiki-lint` supports a headless mode if you want a weekly CI job.
- **More outside opinions** — `perspectives/ask.sh` takes any OpenRouter model ID; adding a model is a one-line skill edit.
- **Team mode** — make `~/wiki` a shared repo; ingests become PRs; review becomes curation.
- **Other agents** — almost nothing here is Claude-specific. The hooks are plain shell on documented events; the skills are instruction files any capable agent can follow. Port the wiring, keep the files.

## Inspiration

- **Zettelkasten** and the [zk](https://github.com/zk-org/zk) lineage of tools — small notes, dense links, tags over hierarchy, the insight that *structure should emerge from connections, not folders*.
- **The Unix philosophy** — plain text as the universal interface, small tools that compose, everything inspectable. The system's guarantee isn't a feature list; it's that you can always just look at the files.
- **Andrej Karpathy's notes-and-LLMs thinking** — append-and-review notes, and the broader idea that an LLM's working memory should live in files it re-reads and maintains, not in hidden state.

## License

MIT — see [LICENSE](LICENSE).
