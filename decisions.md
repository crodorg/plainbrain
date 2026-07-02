# decisions.md — plainbrain

Append-only log of what changed and why. Newest entry is always the last line. This is the
kit dogfooding its own convention: the distribution ships its own audit trail. The *what* is in
git; this file holds the *why*.

2026-07-02 16:10: adopted the kit repo into its own layout (decisions.md + .claude/plainbrain marker; .gitignore narrowed from all of .claude/ to just .claude/plainbrain + .claude/state/) because the flagship of "every project carries decisions.md" was developing with commit messages as its only why-trail — during a Fable architecture audit the rationale for contested calls was unrecoverable, the exact archaeology the system exists to prevent (audit finding P3).
2026-07-02 16:10: ran a Fable-tier (xhigh) whole-architecture audit focused on data gathering, data retrieval, and minimalism; it found the system healthy (~1,630 lines, thesis intact) with four structural problems — an undocumented second schema, safety-net promises the code doesn't keep, wiki-surface.sh drifting into "smart substrate," and retrieval recall hanging on one-line index summaries. Acting on it as a phased refactor.
2026-07-02 16:10: on the audit's schema split (G1), chose to DOCUMENT the trust-roster/attributed-map/`by:`+`depth:` model into wiki/CLAUDE.md and scaffold entities/people.md, rather than strip it from the skills, because the local (richer) system is meant to converge with the kit — not diverge from it — and multi-agent portability wants the page schema explicit so any agent following the instruction files produces conforming pages.
