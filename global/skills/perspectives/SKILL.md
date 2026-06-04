---
name: perspectives
description: Get outside opinions from both Grok and Gemini on the current question, one-shot via OpenRouter. Use when the user says "get perspectives", "ask both", or wants outside views.
---

# perspectives — outside opinions from Grok + Gemini

One-shot fan-out to both models with the same brief. They advise; you and the user
decide and execute. No verdict synthesis — present both views as-is.

## Steps
1. Write ONE self-contained brief to a temp file (e.g. `/tmp/ask-$$.md`) — question plus
   the minimum context needed; the models see nothing else. Never include secrets
   (keys, tokens, env values).
2. Run both in parallel:
   ```sh
   bash ~/.claude/skills/perspectives/ask.sh x-ai/grok-4.3 /tmp/ask-$$.md > /tmp/grok-$$.txt 2>/tmp/grok-$$.err &
   bash ~/.claude/skills/perspectives/ask.sh google/gemini-3.1-pro-preview /tmp/ask-$$.md > /tmp/gemini-$$.txt 2>/tmp/gemini-$$.err &
   wait
   ```
3. Present both verbatim under `## Grok says` / `## Gemini says`. If one failed, show
   the other plus the error. Then ≤3 lines of your own: where they agree/disagree.
   Clean up temp files.
