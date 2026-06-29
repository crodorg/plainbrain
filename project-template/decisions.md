# Decisions — <project-name>

Append-only. One line per decision or resolved inconsistency, newest at the bottom.
Format: `YYYY-MM-DD HH:MM: changed/decided X because Y`
Cite the enacting commit (short-hash) when a decision maps to a specific change.
When a decision reverses an earlier one, end the new line with `— supersedes YYYY-MM-DD HH:MM`
naming the entry it overrides; never edit or delete the old line — the marker shows which won.

Git holds *what* changed; this file holds *why* — fast to read without git archaeology.

---

2026-06-02: initialized from template.
