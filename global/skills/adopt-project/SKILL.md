---
name: adopt-project
description: Bring a project into the knowledge-system layout — git repo, gitignored .claude/state/, core (CLAUDE.md + decisions.md) plus only the modules that fit (plan.md, ARCHITECTURE.md, CONTEXT.md). Works on existing, brand-new, and already-adopted projects (add/drop a module). Use on "adopt this project", "convert this to the kit", "new project", or kit-style work in a repo lacking kit files. Drafts everything for approval before writing.
---

# adopt-project

Run inside the project directory. Goal: the core plus the modules that earn their keep,
with real content, nothing clobbered, hooks live. Adoption is a conversation, not a scan.

**Core (every project):** git repo + `CLAUDE.md` + `decisions.md`.
**Modules (only where they fit):**
- `plan.md` — there is phased execution to drive (driver for execution projects)
- `ARCHITECTURE.md` — there is a codebase to map
- `CONTEXT.md` — Claude needs standing knowledge to work here: philosophy, taste, voice,
  audience, domain constraints (driver for creative/knowledge projects)

No project "types" — hybrids compose modules (a website can carry CONTEXT.md *and*
plan.md). Modules are added or dropped later by re-running this skill.

1. **Survey.** Is it a git repo? If not, flag that hooks have been inert here and
   `git init` (with user OK) + a sensible .gitignore is step one. Read existing
   CLAUDE.md / README / docs; `git log --oneline -30` for trajectory; skim
   `$PLAINBRAIN_DATA/<name>/memory-archive/` if present (MEMORY.md first) — it holds the
   project's prior working state.
2. **Gitignore + activate.** Ensure `.claude/state/` is ignored; `git rm -r --cached` any
   already-tracked markers. Then **activate**: create the tracked `.claude/plainbrain` marker —
   the session hooks (orient, snapshot, distill-reminder) stay INERT until it exists, so
   un-adopted repos are untouched.
3. **Interview.** FIRST question: what kind of work happens here — building in phases,
   collecting ideas, writing, a creative practice? That picks the modules. Then 3-5
   short questions: current goal or direction, what's in flight, what's locked, what
   Claude must know to work well here. Don't guess intent from files.
4. **Draft every chosen file, show them all, get approval BEFORE writing any:**
   - `CLAUDE.md` — merge with existing (keep their rules, add the pointer block from
     the template at `~/.claude/project-template/`). The pointer block lists
     ONLY the files this project carries and names the **driver** (plan.md or
     CONTEXT.md). Lean. Record the same driver in the `.claude/plainbrain` marker as a
     `driver: <file>` line — the session-start hook reads it, so a CONTEXT-driven hybrid
     that also carries a plan.md isn't mis-detected. Omit the line for a core-only project.
   - `decisions.md` — template header; seed timestamped entries for big already-made
     decisions surfaced by interview/archive (marked retroactive).
   - `plan.md` (if chosen) — Goal/Constraints/Decisions (stable) + phased Status
     (volatile) from interview + survey. Mark unknowns explicitly; never invent.
   - `CONTEXT.md` (if chosen) — stable sections (philosophy / taste / constraints) +
     volatile Current direction. Project-specific knowledge only: user-level facts
     belong in `$PLAINBRAIN_WIKI/entities/me.md` — link it, don't copy it.
   - `ARCHITECTURE.md` (if chosen) — codebase map from an actual scan: entry points,
     layout, data flow, how to build/run. Sized to the project: a script gets 10
     lines, a service gets a page.
5. **Commit** (`adopt: knowledge-system layout`). If the memory-archive looked rich,
   suggest wiki-ingest for it.

**Re-adoption** (kit files already present): survey what exists vs what fits, propose
only the delta — add the missing module, activate (drop `.claude/plainbrain`) if missing, or
flag one that never earned its keep (dropping needs explicit user OK; git keeps the history). Never overwrite an existing
plan.md / decisions.md / CONTEXT.md / ARCHITECTURE.md without explicit OK — merge or
extend instead.
