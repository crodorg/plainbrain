---
name: wiki-ingest
description: Integrate a new source into the wiki knowledge base. Use when the user drops a file into the data or notes folder and wants it read, summarized, and cross-referenced into the wiki. Touches multiple pages — source summary, entity pages, concept pages, the index, and the log.
---

# wiki-ingest

The wiki is at `$PLAINBRAIN_WIKI` (default `~/wiki`; read its CLAUDE.md for layout and page
formats). Sources live in `$PLAINBRAIN_DATA` (raw/external, default `~/data`) and
`$PLAINBRAIN_NOTES` (personal, default `~/notes`). Work one source at a time and stay
collaborative unless told to batch.

Steps:

1. **Read the source** the user points to (a path under `$PLAINBRAIN_DATA` or `$PLAINBRAIN_NOTES`). For PDFs or
   images, extract text first, then view images if needed.

2. **Discuss the key takeaways** with the user briefly before writing — confirm what matters
   and what to emphasize.

3. **Search the existing wiki** for related pages (grep titles and bodies). Decide, per entity
   and concept, whether to **edit an existing page** or **create a new one**. Default to editing
   and cross-linking when something already fits; only create when nothing does.

4. **Write a source summary** in `sources/<slug>.md`: frontmatter with `type: source`,
   `source-path:` pointing to the raw file, `by:` (the author — links to their `entities/` page,
   inherits their roster tier), `depth:` (full/partial/skim), and a concise, faithful summary of
   the source's content and claims.

5. **Update the author's entity page and the concept maps**: add facts to the `entities/` page;
   extend relevant concept-page **maps** with attributed lines only, each pinned to its source
   location — `Per <Person> ([<anchor>](<raw-path>#<anchor>)): <claim> — "<verbatim quote>"` (the
   quote is the durable pin; cite it, never a brittle line number). Never write the human-only
   "My read" zone, never synthesize a verdict. Stub any cross-figure conflict as a `comparisons/`
   dispute. Cross-link both directions. A single source may touch 10–15 pages.

6. **Update `index.md`**: add or refresh the one-line entry for every page you created or changed.

7. **Commit** with a message naming the source and noting what it touched — the commit history
   is the activity record (no separate ledger file).

Keep pages small and single-topic. Link by relative markdown path. **Reuse an existing tag
before coining a new one** — grep the current vocabulary (`grep -rho 'tags:.*' entities concepts
comparisons sources | tr ',[]' '\n'`) and prefer a tag already in use; tags are the auto-surface
retrieval key, so synonym drift (`llm` / `llms` / `language-model`) silently degrades recall.
Never modify files in `$PLAINBRAIN_DATA` or `$PLAINBRAIN_NOTES` — they are read-only sources.
