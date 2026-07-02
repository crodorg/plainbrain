# Wiki schema (CLAUDE.md for ~/wiki)

This directory is a **compiled, interlinked knowledge wiki**, co-maintained by you and Claude.
Claude does the bookkeeping (summarizing, cross-referencing, filing, flagging contradictions);
you curate sources, ask questions, and may hand-edit any page. It is plain markdown in git.

## Layout

```
~/wiki/
  overview.md      # top-level synthesis / entry point
  index.md         # catalog of every page (link + one-line summary), read FIRST on query
  log.md           # append-only, chronological, greppable record of ingests/queries/lints
  entities/        # one page per concrete thing: a company, person, product, place
  entities/people.md  # the trust roster: authors/figures + weight tier (see Attribution)
  concepts/        # one page per idea, method, framework, mechanism
  comparisons/     # head-to-head analyses, tables, "X vs Y" pages
  sources/         # one summary page per ingested source, citing the raw file path
  _lint/           # dated lint reports
```

## What belongs here (litmus)

File a fact only if ALL four hold:
1. **Durable** — still true and useful in 6+ months (not status, not WIP).
2. **Cross-project** — would serve a different project or a future question.
3. **About the world** — entities, concepts, methods, comparisons; not one repo's internals.
4. **Cost something to learn** — research, a debugging discovery, an outside opinion;
   cheap-to-rederive facts don't compound.

Fails the test → route down: project-only knowledge → that project's CONTEXT.md /
ARCHITECTURE.md; about the user as a person → `entities/me.md`; ephemeral → nowhere.
Knowledge born in conversation (no source file) is filed directly as a page — update
`index.md`, note "filed from session" in `log.md`; `wiki-ingest` is for real source files.

## Sources live elsewhere

Raw material is **not** stored here. It lives in `~/data` (external/raw files, no git) and
`~/notes` (your personal notes). Every `sources/` page records the raw path so the original
can be reopened:

```
source-path: ~/data/acme/acme-q1-2026.pdf
```

Read the raw file only when a wiki page's summary is insufficient. The wiki is the layer you
work from; raw sources are the fallback.

## Page format

Minimal YAML frontmatter, then prose with relative-link cross-references. Keep frontmatter small.

```markdown
---
title: Acme Bank
type: entity            # entity | concept | comparison | source
created: 2026-06-02
updated: 2026-06-02
sources: [sources/acme-q1-2026.md]
tags: [banking, research, competitor]
---

# Acme Bank

One-paragraph summary of what this is and why it matters.

## Key facts
- ...

## Connections
- Competes with [Initech](../entities/initech.md)
- Relevant to [instant settlement](../concepts/instant-settlement.md)

## Open questions / contradictions
- 2026-06-02: source A says X, source B implies not-X — unresolved.
```

Linking: relative markdown links, e.g. `[Globex](../entities/globex.md)`. Filenames are
lowercase-kebab. One concept per file — small pages so retrieval pulls a node, not a tome.
Tags are the subcategory layer — multiple per page, greppable (`grep -rl 'tags:.*banking'
entities/`); directories stay shallow, links and tags carry the structure.

## Attribution: roster, sources, maps

Knowledge here is **attributed and weighted**, never flattened into one anonymous voice.

- **`entities/people.md` — the trust roster.** One entry per author/figure the wiki tracks,
  each with a **tier** (how much weight their claims carry). Source authors link here and
  inherit the tier; conflicting claims are weighed by it.
- **Source pages carry `by:` and `depth:`.** `by:` links the author to their `people.md` /
  `entities/` page (the source inherits that author's tier); `depth:` is `full | partial | skim`.
- **Concept pages are maps of attributed claims.** Under a `## The map` heading, each bullet is
  one source-claim, attributed and pinned to a verbatim quote — never a brittle line number:
  `- Per <Person> ([anchor](raw-path#anchor)): <claim> — "<verbatim quote>"`.
  `wiki-check.sh` flags any unattributed `## The map` bullet. Claude writes only the map, never
  a synthesized verdict.
- **`## My read` is yours.** A concept page may carry a `## My read` section for your own
  synthesis; Claude never writes or edits it.
- **Disagreements become `comparisons/` disputes** — stub the conflict, don't silently pick a side.

## Workflows (full steps live in the skills)

- **Ingest** (`wiki-ingest`): read a source from `~/data` or `~/notes`; search the existing
  wiki to decide edit-vs-create; write a `sources/` summary citing the raw path; update or
  create the relevant `entities/` and `concepts/` pages with cross-links; flag any contradiction
  with existing claims; update `index.md`; append a `log.md` entry; commit. One source may touch
  10–15 pages — that's expected.
- **Query** (`wiki-query`): read `index.md` first, drill into the relevant pages (raw sources
  only if needed), answer with citations. If the answer is a durable insight (a comparison, a
  synthesis, a discovered connection), **file it back as a new page** so explorations compound.
- **Lint** (`wiki-lint`): scan for contradictions, stale claims, orphan pages (no inbound
  links), missing pages or cross-references, and gaps fillable by a web search; report and fix.

## Maintenance rules

- Editing in place is fine, but prefer to append to "Open questions / contradictions" rather
  than silently overwriting a claim — note *why* it changed.
- After any hand-edit, run `wiki-lint` to reconcile the index and cross-references.
- `index.md` and `log.md` are updated on every ingest. Keep `index.md` terse (a map, not a copy).
- Size thresholds: split `index.md` per-category past ~300 entries; split any page past ~150
  lines. Query cost scales with the index + pages actually read, never with total wiki size.
- `wiki-lint` opens with a deterministic structural pass (`wiki-check.sh`, in the wiki-lint
  skill directory): dead links, index drift, frontmatter, orphans. Runnable any time by hand.
