---
name: wiki-query
description: Answer a question against the wiki knowledge base. Use when the user asks something that the accumulated wiki should know. Reads the index first, drills into relevant pages, answers with citations, and offers to file durable answers back into the wiki as new pages so explorations compound.
---

# wiki-query

The wiki is at `$PLAINBRAIN_WIKI` (default `~/wiki`; read its CLAUDE.md for layout).

**Scope: wiki-only by default.** Answer from the wiki (plus its `$PLAINBRAIN_DATA`/`$PLAINBRAIN_NOTES` raw sources)
and nothing else. Do **not** web search or fetch external sources unless the user explicitly asks
for it. If the wiki lacks enough to answer well, say so plainly and *offer* to go to the web —
don't reach for it unprompted. The whole point of this skill is to report what the wiki knows.

Steps:

1. **Read `index.md` first** to locate the relevant pages — don't load the whole wiki.

2. **Drill into the relevant pages.** Follow cross-links. Open raw sources under `$PLAINBRAIN_DATA`
   or `$PLAINBRAIN_NOTES` only when a page's summary isn't enough to answer well.

3. **Synthesize an answer with citations** — cite the wiki pages you used (and raw source paths
   where a specific fact came from the original). If pages contradict each other, surface the
   contradiction rather than silently picking one. When weighing conflicting claims, weight by the
   author's tier in `entities/people.md` (the trust roster) and name whose view each one is.

4. **Offer to compound it.** If the answer is a durable insight — a comparison, a synthesis, a
   connection you discovered, an analysis worth keeping — offer to file it back into the wiki as
   a new page (usually under `comparisons/` or `concepts/`). This is the whole point: good
   answers shouldn't vanish into chat history.

5. If the user accepts: write the page, add cross-links to and from related pages, update
   `index.md`, append a `log.md` entry (`## [YYYY-MM-DD] query | <topic>`), and commit.

Answers can take whatever form fits — prose, a table, a list. The filing-back step is what
turns querying into accumulation.
