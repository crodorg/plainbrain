#!/bin/sh
# wiki-check.sh — deterministic structural checks for the wiki. No AI, no network.
# Run by wiki-lint as a mechanical pre-pass, or by hand any time.
# Usage: wiki-check.sh [wiki-root]     (default: $PLAINBRAIN_WIKI, else ~/wiki)
# Exit: 0 clean, 1 findings, 2 wiki not found.

[ -f "$HOME/.config/plainbrain/env" ] && . "$HOME/.config/plainbrain/env"
WIKI="${1:-${PLAINBRAIN_WIKI:-$HOME/wiki}}"
cd "$WIKI" || { echo "wiki-check: no wiki at $WIKI" >&2; exit 2; }

pages=$(find entities concepts comparisons sources -name '*.md' 2>/dev/null | sort)

out=$(
  # 1. Dead relative links — every (...*.md) target must resolve from the page's dir.
  for p in $pages index.md overview.md; do
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
    head -20 "$p" | grep -q '^type: *\(entity\|concept\|comparison\|source\)' \
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

  # 5. Source pages whose source-path is missing or no longer resolves.
  for p in sources/*.md; do
    [ -f "$p" ] || continue
    sp=$(grep -m1 '^source-path:' "$p" | sed 's/^source-path: *//')
    if [ -z "$sp" ]; then echo "no source-path: $p"; continue; fi
    case "$sp" in "~/"*) sp="$HOME/${sp#\~/}" ;; esac
    [ -e "$sp" ] || echo "source-path missing: $p -> $sp"
  done

  # 6. Unattributed claim bullets in a concept page "## The map" section.
  for p in concepts/*.md; do
    [ -f "$p" ] || continue
    awk -v f="$p" '
      /^#/ { inmap = ($0 ~ /^#+ The map/) ? 1 : 0; next }
      inmap && /^- / && $0 !~ /^- Per / && $0 !~ /comparisons\// {
        print "unattributed map line: " f " :: " $0 }
    ' "$p"
  done

  # 7. Pages with no `tags:` line — invisible to the wiki-surface hook (can never auto-surface).
  for p in $pages; do
    head -20 "$p" | grep -q '^tags:' || echo "no tags (won't auto-surface): $p"
  done
)

# Coverage rollup (informational; gaps are expected, not failures).
# How many top-level data source-dirs have at least one citing wiki page.
DATA="${PLAINBRAIN_DATA:-$HOME/data}"
if [ -d "$DATA" ]; then
  refs=$(grep -hR '^source-path:' sources 2>/dev/null)
  total=0; covered=0; gaps=""
  for d in "$DATA"/*/; do
    [ -d "$d" ] || continue
    total=$((total + 1)); name=$(basename "$d")
    if printf '%s\n' "$refs" | grep -q "/$name/"; then
      covered=$((covered + 1))
    else
      gaps="$gaps $name"
    fi
  done
  [ "$total" -gt 0 ] && printf 'coverage: %s/%s data source-dirs have >=1 page%s\n' \
    "$covered" "$total" "${gaps:+ — dark:$gaps}"
fi

# Scale advisories (informational) — the documented split thresholds, never a failure.
idx=$(grep -c '\.md)' index.md 2>/dev/null)
[ "${idx:-0}" -gt 300 ] && printf 'scale: index.md has %s entries (>300) — consider per-category index shards\n' "$idx"
big=$(for p in $pages; do
  n=$(wc -l < "$p" 2>/dev/null | tr -d ' ')
  [ "${n:-0}" -gt 150 ] && printf '  %s (%s lines)\n' "$p" "$n"
done)
[ -n "$big" ] && { echo 'scale: pages over ~150 lines (split — one concept per file):'; printf '%s\n' "$big"; }

# Tag histogram (informational) — the auto-surface retrieval vocabulary. Singletons are often
# synonyms/typos to merge; ⚠ marks a tag the wiki-surface hook can't match (multi-word, or under
# 4 chars). Bracket-form `tags: [a, b]` only. Tag hygiene is retrieval recall.
alltags=$(for p in $pages; do
  head -20 "$p" | sed -n 's/^tags:[[:space:]]*\[\(.*\)\]/\1/p' | tr ',' '\n'
done | sed 's/^[[:space:]"'\'']*//; s/[[:space:]"'\'']*$//' | grep -v '^$')
if [ -n "$alltags" ]; then
  echo 'tags (count · tag · ⚠=unsurfaceable):'
  printf '%s\n' "$alltags" | sort | uniq -c | sort -rn | while read -r c t; do
    warn=""
    case "$t" in *" "*) warn=' ⚠multi-word' ;; esac
    [ "$(printf %s "$t" | wc -c)" -lt 4 ] && warn="$warn ⚠short"
    printf '  %3d  %s%s\n' "$c" "$t" "$warn"
  done
fi

# Inbox (informational) — notes touched since the last lint: promotion candidates for the wiki.
# Promotion is manual (wiki-query/ingest); this just keeps the inbox from rotting unseen.
NOTES="${PLAINBRAIN_NOTES:-$HOME/notes}"
if [ -d "$NOTES" ]; then
  lastlint=$(ls -1t _lint/*.md 2>/dev/null | head -1)
  if [ -n "$lastlint" ]; then
    fresh=$(find "$NOTES" -name '*.md' -newer "$lastlint" 2>/dev/null | wc -l | tr -d ' ')
    [ "${fresh:-0}" -gt 0 ] && printf 'inbox: %s note(s) touched since last lint — review for wiki promotion\n' "$fresh"
  fi
fi

count=$(printf '%s\n' "$pages" | grep -c . )
if [ -n "$out" ]; then
  printf '%s\n' "$out"
  printf 'wiki-check: %s finding(s) across %s page(s)\n' \
    "$(printf '%s\n' "$out" | grep -c .)" "$count"
  exit 1
fi
echo "wiki-check: clean ($count pages)"
exit 0
