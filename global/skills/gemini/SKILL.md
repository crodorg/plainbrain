---
name: gemini
description: Get Gemini's outside opinion on the current question or problem, relayed one-shot via OpenRouter. Use when the user says "ask gemini", "what does gemini think", or wants Gemini's take.
---

# gemini — outside opinion from Gemini

One-shot relay. Gemini advises; you and the user decide and execute. Never act on its
reply without the user's go-ahead.

## Steps
1. Write a self-contained brief to a temp file (e.g. `/tmp/ask-gemini-$$.md`). Gemini has
   no access to the conversation or filesystem — include the question plus the minimum
   context it needs (relevant code excerpts, plan slice, constraints). Never include
   secrets (keys, tokens, env values).
2. Run: `bash ~/.claude/skills/perspectives/ask.sh google/gemini-3.1-pro-preview /tmp/ask-gemini-$$.md`
3. Present the reply verbatim under `## Gemini says`, then add your own take in ≤3 lines
   (agree / disagree / why). Clean up the temp file.

On error the script prints the HTTP body to stderr — show it; retry once at most.
