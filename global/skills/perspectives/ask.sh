#!/usr/bin/env bash
# One-shot OpenRouter relay. Usage: ask.sh MODEL PROMPT_FILE
# Prints the model's reply to stdout; errors to stderr, exit 1.
set -u
MODEL="${1:?model required}"
PROMPT_FILE="${2:?prompt file required}"
: "${OPENROUTER_API_KEY:?OPENROUTER_API_KEY not set}"
[ -f "$PROMPT_FILE" ] || { echo "prompt file missing: $PROMPT_FILE" >&2; exit 1; }

# max_tokens budgets reasoning + visible output on OpenRouter; 8000 avoids truncation.
body=$(jq -n --arg m "$MODEL" --rawfile p "$PROMPT_FILE" \
  '{model: $m, messages: [{role: "user", content: $p}], max_tokens: 8000}')

resp=$(curl -sS -m 180 -w '\n__HTTP__%{http_code}' \
  https://openrouter.ai/api/v1/chat/completions \
  -H "Authorization: Bearer $OPENROUTER_API_KEY" \
  -H "Content-Type: application/json" \
  -d "$body") || { echo "curl failed for $MODEL" >&2; exit 1; }

http=${resp##*__HTTP__}
payload=${resp%__HTTP__*}
[ "$http" = "200" ] || { printf 'HTTP %s from %s:\n%s\n' "$http" "$MODEL" "$payload" >&2; exit 1; }

text=$(printf '%s' "$payload" | jq -r '.choices[0].message.content // empty')
[ -n "$text" ] || { printf 'HTTP 200 but empty content from %s:\n%s\n' "$MODEL" "$payload" >&2; exit 1; }
printf '%s\n' "$text"
