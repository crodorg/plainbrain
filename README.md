# plainbrain

**Plain files, whole brain.** A memory and knowledge system for AI coding agents, built from markdown, git, and a handful of small shell scripts. Wired for [Claude Code](https://claude.com/claude-code) out of the box, portable to any agent that can read instructions and run shell. No database, no daemons, no vector store, no subscriptions.

## The problem

Every AI coding session starts with amnesia. You re-explain your project, re-justify decisions you made weeks ago, re-paste the same context. Built-in memory features help, but they write to opaque files behind your back — you can't easily see what the model "knows" about you, audit it, or fix it when it's wrong. And when the context window fills up and gets compacted, nuance quietly dies.

Meanwhile, the actual knowledge you accumulate — research, comparisons, hard-won conclusions — evaporates into chat history you'll never scroll back through.

## The idea in 60 seconds

Turn implicit memory into **three explicit memories, each a plain file you can read**:

```
conversation ──"distill"───────▶  <project>/plan.md + decisions.md    (project state)
raw documents ──drop──────────▶  ~/data/<project>/   (no git)  ──┐
quick thoughts ──capture──────▶  ~/notes/            (git)      ──┤──"ingest"──▶  ~/wiki
questions ──"query the wiki"──▶  cited answer ──filed back──────────────────────▶  (git)
```

1. **Project state** — every repo carries `decisions.md` (append-only log of *what changed and why*, timestamped) plus the modules that fit: `plan.md` (intent, for projects that execute in phases), `CONTEXT.md` (standing knowledge — philosophy, taste, voice, constraints — for creative and idea projects), `ARCHITECTURE.md` (codebase map). The project's `CLAUDE.md` names which file is the **driver**; the AI reads it at session start and updates it at session end. There are no project "types" — hybrids compose modules.
2. **Knowledge** — `~/wiki`: small, single-topic markdown pages (entities, concepts, comparisons, sources) cross-linked with relative links and cataloged in one `index.md`. The AI does the bookkeeping; you supervise.
3. **Inbox** — `~/notes`: your own notes, a first-class source the wiki can ingest.

Three hooks keep git honest in any project you've **adopted**: session start injects recent git history and a pointer to the driver; before context compaction and on exit, work is snapshotted to a *private ref* — recoverable, but never a commit on your branch — and the next session opens by asking what to do with it. Un-adopted repos are left completely alone (no orientation, no snapshots, no surprises). **Forgetting to save is always recoverable.**

The day-to-day surface is two commands: *adopt a project once, distill at the end of sessions.* Everything else is automatic (hooks) or on-demand (ask the wiki, ingest a document).

## Dumb and smart at the same time

This is the design thesis, and the reason the system should still work years from now.

**The substrate is deliberately dumb.** Markdown files. POSIX shell. Git. An "index" that is literally a list of links. A validator that is 60 lines of grep. There is nothing to install, migrate, host, or debug at 2am. Every single thing the AI "remembers" is a line in a file you can read, grep, hand-edit, and `git diff`. When the AI is wrong about something, you can see exactly where and fix it with a text editor.

**The smart layer is rented at runtime.** The skills — ingest, query, lint, distill, adopt-project — are plain-English instruction files the model reads when invoked. The intelligence (what matters, what contradicts what, where a fact belongs, what to cross-link) is applied fresh by whatever model you run, with judgment, in conversation with you. When models get smarter, this whole system gets smarter, with zero code changes.

Dumb substrate, smart runtime. Systems built the other way around — smart substrate (embeddings, schemas, agents-with-state) — rot when their runtime assumptions change. Files don't rot.

## What's in the box

| Path | What it is |
|---|---|
| `global/hooks/` | 4 hooks, **inert until a repo is adopted**: session-start (inject git state + driver pointer + pending-work flag), pre-compact + session-end (snapshot the tree to a private ref), wiki-surface (on your prompt, inject any wiki page whose tags match the topic — uses python3) |
| `global/skills/adopt-project/` | Bring any project — new or existing — into the layout: the interview picks the modules that fit; files drafted and approved before written |
| `global/skills/distill/` | The end-of-session sweep: proposes 0–3 durable wiki/skill/me.md items for your approval, routes them to their homes, commits — you are the noise gate |
| `global/skills/wiki-ingest/` | Source → wiki: summary page, entity/concept updates, cross-links, contradiction flags, index + log |
| `global/skills/wiki-query/` | Index-first retrieval, cited answers, offers to file durable answers back as new pages |
| `global/skills/wiki-lint/` | Health check: deterministic `wiki-check.sh` pre-pass (dead links, index drift, orphans, scale advisories) + semantic review |
| `global/bin/plainbrain` | List, recover, or prune the private-ref snapshots (`plainbrain wip`) |
| `global/CLAUDE.md` | Lean global rules: plan discipline, git discipline, where things live |
| `global/settings.json` | The hook wiring (merged into yours — never overwritten) |
| `install.sh` / `update.sh` | Idempotent, backup-first installer + kit-file updater |
| `wiki/` | Wiki scaffold: schema doc, index, log, overview |
| `project-template/` | Core templates (CLAUDE.md, decisions.md) + the modules (plan.md, CONTEXT.md, ARCHITECTURE.md) |

## Install

Requirements: Claude Code, git, bash — that's the whole stack. (One optional hook, wiki-surface, additionally uses python3; without it that single hook stays off and prints a one-time note, and nothing else is affected.)

```sh
git clone https://github.com/crodorg/plainbrain
cd plainbrain
./install.sh
```

`install.sh` is idempotent and backup-first — it never clobbers your data or merged config. It creates the four homes and scaffolds an empty wiki, installs the hooks / skills / `plainbrain` CLI / project template into `~/.claude`, installs `global/CLAUDE.md` only if you don't already have one (otherwise saves it as `CLAUDE.md.plainbrain-new` to merge), merges **only** the hooks block into your `settings.json` (with `jq` if present, else prints it to paste — your permissions/env/statusLine are never touched), and writes `~/.config/plainbrain/env`.

It's all shell — read it before you run it. Re-run it any time; `./update.sh` later refreshes just the kit-owned files (hooks, skills, CLI, template) without touching your config or data.

**Relocating the homes.** Each home honors a `$PLAINBRAIN_*` env var (`WIKI`, `DATA`, `PROJECTS`, `NOTES`), defaulting to `~/wiki|data|projects|notes`. Edit `~/.config/plainbrain/env`, then add this to your shell rc so both the hooks and Claude inherit it:

```sh
[ -f ~/.config/plainbrain/env ] && . ~/.config/plainbrain/env
```

Optional shell aliases for the two repos nothing auto-commits:

```sh
alias wiki-save='W="${PLAINBRAIN_WIKI:-$HOME/wiki}"; git -C "$W" add -A && git -C "$W" commit -m "wiki: $(date -u +%FT%TZ)"'
alias notes-save='N="${PLAINBRAIN_NOTES:-$HOME/notes}"; git -C "$N" add -A && git -C "$N" commit -m "notes: $(date -u +%FT%TZ)"'
```

Verify: in a repo, run "adopt this project" to activate it, then open Claude Code and check the injected "Session context" block (Ctrl+O shows hook output), or look for `.claude/state/.session-start`.

## Daily use

| When | You do |
|---|---|
| Project's first contact (new or existing) | "adopt this project" — once, ever |
| End of a work session | "distill" — the one habit |
| A document worth keeping arrives | drop it in `~/data/<project>/`, then "ingest this into the wiki" |
| You need something you once knew | "query the wiki: …" — answer comes back with file citations |
| A passing thought | capture to `~/notes` however you like; promote to the wiki later |
| Monthly-ish | "lint the wiki" — contradictions, dead links, orphans |

And what you *don't* do: you never organize the wiki by hand (ingest does the filing, lint does the auditing), and you never lose work to a crashed or forgotten session (private-ref snapshots + next-session triage).

## Why it's built this way

- **Memory routed by kind.** Project state, world knowledge, and personal notes live in separate homes with separate lifecycles, not one opaque bucket. Nothing is written behind your back; `git log` is the audit trail.
- **Retrieval by reading, not similarity.** An index file plus links the model follows, the way a person uses a wiki. Cost scales with the index and the pages actually read, not with the size of the corpus. No embeddings to drift, no re-indexing, no embedding scores to tune, and every citation is a file path you can open. (The one proactive-surfacing hook ranks tag matches with a plain, hand-editable stoplist — a dumb knob in a file, not an opaque vector score.)
- **Co-maintained, not hand-maintained.** The AI does the tedious part — filing, cross-linking, index updates, contradiction flags — and you do the judgment part: what matters and what's true. The upkeep that kills most second brains is exactly the part that's delegated.
- **No runtime to rot.** No server, no schema, no daemon. The "framework" is conventions written in markdown. It works offline, survives tool churn, and every piece is replaceable with `sed`.

## Ideas to consider

Even if you don't adopt the whole thing, a few pieces stand on their own:

- **The contradiction ledger.** Wiki pages have a dated "Open questions / contradictions" section. New facts that conflict with old ones get *recorded as disagreement*, never silently overwritten. Your knowledge base admits uncertainty.
- **The append-only decisions file.** One timestamped line per decision: `2026-06-04 16:45: chose X because Y`. Six months later, "why on earth did we do it this way?" is a grep, not an archaeology dig. When a later decision reverses an earlier one, its line carries a `— supersedes <date>` marker — the old line stays put, so the log shows which call won instead of quietly accumulating contradictions.
- **A compaction-proof rationale scratch.** The *why* behind a decision lives in the conversation — exactly what context compaction discards. So as it works, the agent parks each rationale on a line in an ephemeral, gitignored `decisions.scratch`; it survives the compaction, and the end-of-session distill folds the approved lines into `decisions.md`. The reasoning outlives the context window without forcing an approval-gated write for every passing thought.
- **Private-ref safety nets.** In an adopted repo, context compaction and session exits snapshot your tree to a private git ref — one per session, so two terminals open on the same repo never overwrite each other's backup — recoverable via the `plainbrain` CLI, but never a commit on your branch, and never anything at all in a repo you haven't adopted. The next session flags it and asks: distill, keep, or discard. Laziness is a recoverable state.
- **A warm-resume pointer.** At the end of a task the agent writes the next few steps — and any open questions — to a small throwaway file. After you clear the context, you read that file *outside* the model (a terminal popup, a status line, plain `cat`) and paste back only the one phrase that restarts the work. The next move survives a context reset without spending a single token to re-derive it, and the display is whatever your terminal already does.
- **A lazily-loaded self page.** Your standing philosophy, taste, and voice live in one wiki page (`~/wiki/entities/me.md`) behind a one-line global pointer — read when the work is creative or preference-sensitive, never taxing the context of an ordinary debugging session.
- **Deterministic verification.** `wiki-check.sh` proves the wiki's structural health (dead links, index drift, orphans, pages with no tags that could never surface) with zero AI involvement. Trust, but grep.

## Not just Claude

plainbrain ships wired for Claude Code because that's where it was born, but nothing about
the *system* is Claude-specific. The memories are markdown. The hooks are plain shell scripts
fired on ordinary lifecycle events (session start, context compaction, session end, prompt
submit). The skills are natural-language instruction files — any capable model can follow them.

To port it: re-wire the four hooks to your agent's equivalent events, and expose the skill
files as instructions your agent loads on demand. The files themselves — `plan.md`,
`decisions.md`, the wiki — don't care what reads them. That's the point: your accumulated
knowledge shouldn't be hostage to this year's tool.

## Who this is for

**A good fit if you:** live in Claude Code across multiple projects; want to *audit* what your AI remembers; accumulate research/decisions that deserve to outlive chat history; like plain text and git; work across machines (everything syncs as ordinary repos).

**A bad fit if you:** want fully-automatic zero-habit memory (this asks for one habit: "distill"); need true team-concurrent editing of shared knowledge (git merges of prose are mediocre); have a corpus so large it genuinely needs semantic search (see below).

## Expanding it

The dumb substrate makes extensions easy bolt-ons rather than migrations:

- **Semantic search** — when `index.md` outgrows grep, add an embedding index *next to* the files. The files stay canonical; the index is disposable.
- **Scheduled lint** — the system is deliberately cron-free (nothing runs behind your back), but `wiki-lint` supports a headless mode if you want a weekly CI job.
- **Outside opinions** — add a skill that relays a question to a second model (any API) and returns its take verbatim; durable opinions land in `decisions.md` like any other decision input.
- **Team mode** — make `~/wiki` a shared repo; ingests become PRs; review becomes curation.

## Inspiration

- **Zettelkasten** and the [zk](https://github.com/zk-org/zk) lineage of tools — small notes, dense links, tags over hierarchy, the insight that *structure should emerge from connections, not folders*.
- **The Unix philosophy** — plain text as the universal interface, small tools that compose, everything inspectable. The system's guarantee isn't a feature list; it's that you can always just look at the files.
- **Andrej Karpathy's notes-and-LLMs thinking** — append-and-review notes, and the broader idea that an LLM's working memory should live in files it re-reads and maintains, not in hidden state.

## License

MIT — see [LICENSE](LICENSE).
