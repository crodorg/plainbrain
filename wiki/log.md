# Log

Append-only, chronological record of what happened to the wiki and when: ingests, queries
filed back, and lint passes. Each entry starts with a consistent prefix so the log is
parseable with plain unix tools:

```
grep "^## \[" log.md | tail -5      # last 5 entries
grep "ingest"  log.md               # all ingests
```

Format: `## [YYYY-MM-DD] <op> | <title>` where `<op>` is `ingest`, `query`, or `lint`.

---

## [2026-06-02] init | wiki scaffolded
Created the structure (overview, index, log, entities, concepts, comparisons, sources).
