---
name: wiki-ingest
description: Integrate a new source into the ~/wiki knowledge base. Use when the user drops a file into ~/data or ~/notes and wants it read, summarized, and cross-referenced into the wiki. Touches multiple pages — source summary, entity pages, concept pages, the index, and the log.
---

# wiki-ingest

The wiki is at `~/wiki` (read its CLAUDE.md for layout and page formats). Sources live in
`~/data` (raw/external) and `~/notes` (personal). Work one source at a time and stay
collaborative unless told to batch.

Steps:

1. **Read the source** the user points to (a path under `~/data` or `~/notes`). For PDFs or
   images, extract text first, then view images if needed.

2. **Discuss the key takeaways** with the user briefly before writing — confirm what matters
   and what to emphasize.

3. **Search the existing wiki** for related pages (grep titles and bodies). Decide, per entity
   and concept, whether to **edit an existing page** or **create a new one**. Default to editing
   and cross-linking when something already fits; only create when nothing does.

4. **Write a source summary** in `sources/<slug>.md`: frontmatter with `type: source`, a
   `source-path:` field pointing to the raw file, and a concise summary of the source's content
   and claims.

5. **Update entity and concept pages**: add the new facts, add cross-links both directions, and
   under "Open questions / contradictions" note anything that conflicts with existing claims
   (date it). A single source may legitimately touch 10–15 pages.

6. **Update `index.md`**: add or refresh the one-line entry for every page you created or changed.

7. **Append to `log.md`**: `## [YYYY-MM-DD] ingest | <source title>` plus a one-line note of
   what it touched.

8. **Commit** with a message naming the source.

Keep pages small and single-topic. Link by relative markdown path. Never modify files in
`~/data` or `~/notes` — they are read-only sources.
