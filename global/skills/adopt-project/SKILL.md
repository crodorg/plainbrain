---
name: adopt-project
description: Bring a project into the knowledge-system layout — git repo, gitignored .claude/state/, and the four kit files (CLAUDE.md, plan.md, decisions.md, ARCHITECTURE.md) with real content. Works on existing projects AND brand-new empty dirs (template + interview). Use when the user says "adopt this project", "convert this to the kit", "new project", or kit-style work starts in a repo lacking plan.md. Drafts everything for approval before writing.
---

# adopt-project

Run inside the project directory. Goal: the four kit files with real content,
nothing clobbered, hooks live. Adoption is a conversation, not a scan.

1. **Survey.** Is it a git repo? If not, flag that hooks have been inert here and
   `git init` (with user OK) + a sensible .gitignore is step one. Read existing
   CLAUDE.md / README / docs; `git log --oneline -30` for trajectory; skim
   `~/data/<name>/` if present for prior working state.
2. **Gitignore.** Ensure `.claude/state/` is ignored; `git rm -r --cached` any
   already-tracked markers.
3. **Interview.** 3-5 short questions: current goal, what's in flight, what's
   locked, what's next. Don't guess intent from code.
4. **Draft all four files, show them, get approval BEFORE writing any:**
   - `CLAUDE.md` — merge with existing (keep their rules, add kit pointers
     block from the `project-template/` directory of this kit, wherever it
     was cloned). Lean.
   - `plan.md` — Goal/Constraints/Decisions (stable) + phased Status (volatile)
     from interview + survey. Mark unknowns explicitly; never invent.
   - `decisions.md` — template header; seed 3-8 timestamped entries for big
     already-made decisions surfaced by the interview (marked retroactive).
   - `ARCHITECTURE.md` — codebase map from an actual scan: entry points, layout,
     data flow, how to build/run. Sized to the project: a script gets 10 lines,
     a service gets a page.
5. **Commit** (`adopt: knowledge-system layout`). If prior working state looked
   rich, suggest wiki-ingest for it.

Never overwrite an existing plan.md / decisions.md / ARCHITECTURE.md without
explicit OK — merge or extend instead.
