---
name: grok
description: Get Grok's outside opinion on the current question or problem, relayed one-shot via OpenRouter. Use when the user says "ask grok", "what does grok think", or wants Grok's take.
---

# grok — outside opinion from Grok

One-shot relay. Grok advises; you and the user decide and execute. Never act on its
reply without the user's go-ahead.

## Steps
1. Write a self-contained brief to a temp file (e.g. `/tmp/ask-grok-$$.md`). Grok has no
   access to the conversation or filesystem — include the question plus the minimum
   context it needs (relevant code excerpts, plan slice, constraints). Never include
   secrets (keys, tokens, env values).
2. Run: `bash ~/.claude/skills/perspectives/ask.sh x-ai/grok-4.3 /tmp/ask-grok-$$.md`
3. Present the reply verbatim under `## Grok says`, then add your own take in ≤3 lines
   (agree / disagree / why). Clean up the temp file.

On error the script prints the HTTP body to stderr — show it; retry once at most.
