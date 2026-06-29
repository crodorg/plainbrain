#!/bin/sh
# Wiki auto-surface — fires on UserPromptSubmit (and optionally PreToolUse:Bash; see
# settings.json). Adoption-gated like the other hooks: does nothing unless this repo carries
# a .claude/plainbrain marker, so un-adopted repos and non-repo sessions get nothing.
# Non-blocking (always exits 0), silent on no match, once-per-tag-per-session.
# Matches a page's `tags:` (bracket OR YAML block form) against the words in the user's prompt
# (or the Bash command) + cwd; on a hit, injects the page's H1 + first paragraph.
# A matched tag fires only once per session (a broad project tag won't dribble its pages out
# call after call). Tuning knob: STOP (stoplist) + MIN_LEN below. Needs python3 — prints a
# one-time note and stays off if it's missing.

PAYLOAD=$(cat 2>/dev/null)
[ -z "$PAYLOAD" ] && exit 0

# Adoption gate — like the other hooks, stay out of un-adopted repos and non-repo sessions,
# so the "un-adopted repos get nothing, no surprises" promise holds for every hook.
root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
[ -f "$root/.claude/plainbrain" ] || exit 0

WIKI="${PLAINBRAIN_WIKI:-$HOME/wiki}"
STATE_DIR="$HOME/.claude/state"
[ -d "$WIKI" ] || exit 0
mkdir -p "$STATE_DIR" 2>/dev/null || exit 0

# This hook uses python3 for robust JSON parsing (parsing arbitrary shell commands out of the
# payload in pure sh would be worse). If python3 is absent, surface a one-time note instead of
# dying silently, then stay off — nothing else in plainbrain needs python3.
if ! command -v python3 >/dev/null 2>&1; then
  notice="$STATE_DIR/.wiki-surface-nopython"
  if [ ! -f "$notice" ]; then
    : > "$notice" 2>/dev/null
    echo "ℹ️ plainbrain: wiki auto-surfacing needs python3, which isn't on PATH — that hook is off (everything else works). Install python3, or remove the wiki-surface hook from settings.json to silence this. (shown once)"
  fi
  exit 0
fi

export PAYLOAD WIKI STATE_DIR

python3 <<'PY' 2>/dev/null || exit 0
import os, re, json

# Page type -> surfacing priority (lower = surfaced first). A gotcha/concept beats a
# project overview, which beats a raw source archive.
TYPE_RANK = {"concept": 0, "comparison": 0, "entity": 1, "source": 2, "overview": 3}

def parse_tags(chunk):
    """Front-matter tags, tolerating both `tags: [a, b]` and the YAML block form
    (`tags:` then `  - a` lines). A page authored either way must be surfaceable."""
    m = re.search(r"(?m)^tags:\s*\[(.*?)\]", chunk)
    if m:
        raw = m.group(1).split(",")
    else:
        m2 = re.search(r"(?m)^tags:[ \t]*\r?\n", chunk)   # end() lands after the newline
        if not m2:
            return []
        raw = []
        for line in chunk[m2.end():].splitlines():
            mm = re.match(r"\s*-\s+(.+)", line)
            if not mm:              # first non-list line (next key or blank) ends the block
                break
            raw.append(mm.group(1))
    return [t.strip().strip("\"'").lower() for t in raw]

def main():
    wiki = os.environ["WIKI"]
    state_dir = os.environ["STATE_DIR"]
    try:
        payload = json.loads(os.environ.get("PAYLOAD", "{}"))
    except Exception:
        return
    event = payload.get("hook_event_name", "") or ""
    cwd = payload.get("cwd", "") or ""
    session = re.sub(r"[^A-Za-z0-9_.-]", "", payload.get("session_id", "") or "nosession")

    # Surface to match on: the user's prompt on UserPromptSubmit, else the Bash command.
    # cwd is always folded in, so working in a tagged repo surfaces its pages.
    if event == "UserPromptSubmit":
        text = payload.get("prompt", "") or ""
    else:
        text = (payload.get("tool_input") or {}).get("command", "") or ""

    # Words actually present (>= MIN_LEN chars).
    MIN_LEN = 4
    haystack = (text + " " + cwd).lower()
    words = set(re.findall(r"[a-z0-9][a-z0-9-]{%d,}" % (MIN_LEN - 1), haystack))
    if not words:
        return

    # Generic terms that would fire on noise: path-structural words (always in a cwd),
    # shell builtins, and broad low-signal tags. This is the main tuning surface —
    # add YOUR wiki's overly-general tags to the last group so they don't fire on
    # incidental mentions.
    STOP = {
        # path-structural — present in nearly every cwd / path
        "home", "user", "projects", "project", "data", "notes", "note", "wiki",
        "claude", "code", "global", "skills", "hooks", "state", "root",
        "main", "temp", "dist", "sources", "entities", "concepts", "comparisons",
        "config", "local", "cache", "target", "index", "overview",
        # shell builtins / ubiquitous command words
        "source", "test", "tests", "build", "make", "sudo", "grep",
        "find", "echo", "bash", "shell", "file", "files", "page",
        # broad / low-signal tags (examples — tune to your wiki's tag vocabulary)
        "agent", "agents", "tool", "tools", "tooling", "security", "library",
        "coding", "automation", "quality", "comparison",
    }

    # Pass 1: read front-matter tags + type from every page; doc-frequency per tag.
    data = []
    df = {}
    for dp, _dirs, files in os.walk(wiki):
        if os.sep + "_lint" in dp or os.sep + ".git" in dp:
            continue
        for fn in files:
            if not fn.endswith(".md") or fn == "index.md":
                continue
            p = os.path.join(dp, fn)
            try:
                with open(p, errors="ignore") as f:
                    chunk = f.read(1500)
            except OSError:
                continue
            tags = [t for t in parse_tags(chunk) if len(t) >= MIN_LEN and t not in STOP]
            if not tags:
                continue
            tm = re.search(r"(?m)^type:\s*(\S+)", chunk)
            typ = tm.group(1).strip().lower() if tm else ""
            data.append((p, tags, typ))
            for t in set(tags):
                df[t] = df.get(t, 0) + 1

    # Session dedupe: a matched tag fires once; a page never repeats.
    seen_path = os.path.join(state_dir, "wiki-surfaced-%s.txt" % session)
    seen_tags, seen_pages = set(), set()
    try:
        with open(seen_path, errors="ignore") as f:
            for line in f:
                line = line.strip()
                if line.startswith("tag:"):
                    seen_tags.add(line[4:])
                elif line.startswith("page:"):
                    seen_pages.add(line[5:])
    except OSError:
        pass

    # Pass 2: a page is a candidate if one of its still-fresh tags is a whole word in
    # the haystack. Rank by type, then tag rarity, then tag length.
    cands = []
    for p, tags, typ in data:
        if p in seen_pages:
            continue
        fresh = [t for t in tags if t in words and t not in seen_tags]
        if not fresh:
            continue
        best = min(fresh, key=lambda t: (df.get(t, 999), -len(t)))
        cands.append((TYPE_RANK.get(typ, 1), df.get(best, 999), -len(best), p, best))
    if not cands:
        return
    cands.sort(key=lambda x: (x[0], x[1], x[2]))
    chosen = cands[:2]  # cap injected pages per call

    def summarize(path):
        try:
            with open(path, errors="ignore") as f:
                txt = f.read(4000)
        except OSError:
            return os.path.basename(path), ""
        body = re.sub(r"(?s)\A---.*?\n---\s*", "", txt, count=1)
        lines = body.splitlines()
        i = 0
        while i < len(lines) and not lines[i].startswith("# "):
            i += 1
        title = lines[i][2:].strip() if i < len(lines) else os.path.basename(path)
        i += 1
        while i < len(lines) and not lines[i].strip():
            i += 1
        para = []
        while i < len(lines) and lines[i].strip() and not lines[i].startswith("#"):
            para.append(lines[i].strip())
            i += 1
        return title, " ".join(para)

    parts, fired_tags, fired_pages = [], set(), []
    for _tr, _dfv, _nl, p, best in chosen:
        title, para = summarize(p)
        if len(para) > 500:
            para = para[:500].rstrip() + "…"
        rel = os.path.relpath(p, wiki)
        parts.append("**%s**\n%s\n→ %s/%s  (matched tag: %s)" % (title, para, wiki, rel, best))
        fired_pages.append(p)
        fired_tags.add(best)

    ctx = ("📖 Relevant wiki page(s) for what you're working on — read before proceeding if on-topic:\n\n"
           + "\n\n".join(parts))

    try:
        with open(seen_path, "a") as f:
            for t in fired_tags:
                f.write("tag:%s\n" % t)
            for p in fired_pages:
                f.write("page:%s\n" % p)
    except OSError:
        pass

    # UserPromptSubmit takes raw stdout as context; PreToolUse needs the JSON form.
    if event == "UserPromptSubmit":
        print(ctx)
    else:
        print(json.dumps({"hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "additionalContext": ctx,
        }}))

try:
    main()
except Exception:
    pass
PY
exit 0
