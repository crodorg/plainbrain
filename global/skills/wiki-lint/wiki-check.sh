#!/bin/sh
# wiki-check.sh — deterministic structural checks for the wiki. No AI, no network.
# Run by wiki-lint as a mechanical pre-pass, or by hand any time.
# Usage: wiki-check.sh [wiki-root]     (default: ~/wiki)
# Exit: 0 clean, 1 findings, 2 wiki not found.

WIKI="${1:-$HOME/wiki}"
cd "$WIKI" || { echo "wiki-check: no wiki at $WIKI" >&2; exit 2; }

pages=$(find entities concepts comparisons sources -name '*.md' 2>/dev/null | sort)

out=$(
  # 1. Dead relative links — every (...*.md) target must resolve from the page's dir.
  for p in $pages index.md overview.md log.md; do
    [ -f "$p" ] || continue
    dir=$(dirname "$p")
    sed 's/<!--.*-->//g' "$p" 2>/dev/null \
      | grep -o ']([^)]*\.md[^)]*)' \
      | sed 's/^](//; s/)$//; s/#.*$//' \
      | sort -u \
      | while IFS= read -r t; do
          [ -n "$t" ] || continue
          case "$t" in http://*|https://*|/*|"~"*) continue ;; esac
          [ -f "$dir/$t" ] || echo "dead link: $p -> $t"
        done
  done

  # 2. Category pages missing from index.md.
  for p in $pages; do
    grep -qF "$p" index.md 2>/dev/null || echo "not in index: $p"
  done

  # 3. Missing or invalid frontmatter type.
  for p in $pages; do
    head -10 "$p" | grep -q '^type: *\(entity\|concept\|comparison\|source\)' \
      || echo "missing/invalid frontmatter type: $p"
  done

  # 4. Orphan candidates — no inbound link from any other page (index/log don't count).
  for p in $pages; do
    base=$(basename "$p")
    hit=0
    for q in $pages overview.md; do
      [ "$q" = "$p" ] && continue
      [ -f "$q" ] || continue
      grep -q "$base" "$q" 2>/dev/null && { hit=1; break; }
    done
    [ "$hit" -eq 0 ] && echo "orphan candidate (no inbound page links): $p"
  done
)

count=$(printf '%s\n' "$pages" | grep -c . )
if [ -n "$out" ]; then
  printf '%s\n' "$out"
  printf 'wiki-check: %s finding(s) across %s page(s)\n' \
    "$(printf '%s\n' "$out" | grep -c .)" "$count"
  exit 1
fi
echo "wiki-check: clean ($count pages)"
exit 0
