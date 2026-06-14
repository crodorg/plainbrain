---
name: wiki-lint
description: Health-check the wiki knowledge base. Use periodically to find contradictions, stale claims, orphan pages, missing pages or cross-references, and data gaps. Produces a dated report and proposes fixes. Keeps the wiki healthy as it grows.
---

# wiki-lint

The wiki is at `$PLAINBRAIN_WIKI` (default `~/wiki`; read its CLAUDE.md for layout).

First run the deterministic pre-pass — `wiki-check.sh` in this skill's directory (POSIX, no
AI): dead relative links, pages missing from `index.md`, missing/invalid frontmatter `type:`,
orphan candidates, source-path integrity, and scale advisories (index past ~300 entries, pages
past ~150 lines → prompt the documented per-category / per-page split). Fold its findings into
the report, then do the semantic passes below.

Scan for:

1. **Contradictions** — pages that assert conflicting things. Check the "Open questions /
   contradictions" sections and the claims across related pages.
2. **Stale claims** — statements superseded by a newer source. Use `log.md` dates and source
   dates to spot what's outdated.
3. **Orphan pages** — pages with no inbound links. Either link them in or question whether they
   should exist.
4. **Missing pages** — entities or concepts referenced repeatedly but lacking their own page.
5. **Missing cross-references** — pages that clearly relate but don't link to each other.
6. **Gaps** — open questions that a quick web search could resolve. List them; offer to fill.

Output:

- Write a dated report to `_lint/<YYYY-MM-DD>.md` summarizing findings.
- Propose concrete fixes. Apply the ones the user approves (or, in headless/cron mode, apply
  safe structural fixes — adding cross-links, fixing the index — and only *flag* substantive
  ones like contradictions for human review).
- Append a `log.md` entry (`## [YYYY-MM-DD] lint | N findings`) and commit.

For a large wiki, lint in **batches** (e.g. a category at a time) to stay within context, and
keep a running scratchpad of findings across batches.
