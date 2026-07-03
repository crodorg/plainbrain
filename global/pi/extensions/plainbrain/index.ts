// @ts-nocheck — loaded and transpiled by Pi's runtime (jiti), not type-checked here;
// `node:` builtins resolve at run time, so a bare editor tsc without @types/node is noise.
//
// plainbrain lifecycle adapter for the Pi coding agent.
//
// Re-homes plainbrain's four Claude-Code lifecycle hooks onto Pi's extension events
// WITHOUT changing the scripts — the same shell in ~/.claude/hooks/ serves both harnesses
// (Claude Code fires them from settings.json; this fires them from Pi's lifecycle).
//
//   session-start.sh   -> session_start        (run for side effects; inject stdout next turn)
//   wiki-surface.sh    -> before_agent_start    (per prompt; inject stdout as a message)
//   pre-compact.sh     -> session_before_compact (snapshot only, no context)
//   session-end.sh     -> session_shutdown      (snapshot only, no context)
//   gate.sh            -> tool_call             (opt-in enforcement; deny -> {block, reason})
//
// The scripts read a Claude-shaped payload as JSON on stdin. We feed that via the child's
// stdin (never argv — keeps the prompt text out of `ps`) and run each in ctx.cwd, which the
// scripts use for their git adoption gate. All four self-gate on the `.claude/plainbrain`
// marker, so we run them unconditionally and let un-adopted repos no-op.
//
// Hard rule: a throw from a handler (especially before_agent_start) breaks the user's turn.
// Every spawn is wrapped, times out, and degrades to "no context" — never to an error.

import { execFile } from "node:child_process";
import { homedir } from "node:os";
import { join, resolve } from "node:path";

const HOOKS = join(process.env.CLAUDE_HOME || join(homedir(), ".claude"), "hooks");

// Stable session id from Pi's session file (persists across resume, matching Claude Code's
// session_id semantics). Empty for ephemeral sessions -> the scripts fall back to a timestamp.
function sid(ctx) {
  try {
    const f = ctx?.sessionManager?.getSessionFile?.();
    if (!f) return "";
    return (f.split(/[\\/]/).pop() || "").replace(/\.[^.]+$/, "");
  } catch {
    return "";
  }
}

// Run a hook script with `payload` on stdin, in `cwd`, capped at `timeout` ms.
// Resolves to stdout (or "" on any failure). Never rejects.
function runHook(script, payload, cwd, timeout) {
  return new Promise((resolve) => {
    let child;
    try {
      child = execFile(
        "bash",
        [join(HOOKS, script)],
        { cwd, timeout, maxBuffer: 4 << 20 },
        (err, stdout) => resolve(err ? "" : stdout || ""),
      );
    } catch {
      return resolve("");
    }
    try {
      child.stdin.end(JSON.stringify(payload));
    } catch {
      // spawn raced or stdin unavailable; the callback still resolves us
    }
  });
}

export default function (pi) {
  // Session start: capture git state + driver pointer + pending-work flag, inject next turn.
  // Skip `reload` — same conversation, context already present.
  pi.on("session_start", async (event, ctx) => {
    try {
      if (event?.reason === "reload") return;
      const out = await runHook("session-start.sh", { session_id: sid(ctx) }, ctx.cwd, 15000);
      if (out.trim()) {
        pi.sendMessage(
          { customType: "plainbrain-session-start", content: out, display: false },
          { deliverAs: "nextTurn" },
        );
      }
    } catch {
      // never let a context injection break session startup
    }
  });

  // Per prompt: surface any wiki page whose tags match the prompt (title + path only).
  pi.on("before_agent_start", async (event, ctx) => {
    try {
      const out = await runHook(
        "wiki-surface.sh",
        {
          hook_event_name: "UserPromptSubmit",
          prompt: event?.prompt || "",
          cwd: ctx.cwd,
          session_id: sid(ctx),
        },
        ctx.cwd,
        10000,
      );
      if (out.trim()) {
        return { message: { customType: "plainbrain-wiki", content: out, display: false } };
      }
    } catch {
      // swallow: a wiki miss must never break the turn
    }
  });

  // Before compaction: byte-safety snapshot of the full tree to a private ref.
  pi.on("session_before_compact", async (_event, ctx) => {
    try {
      await runHook("pre-compact.sh", { session_id: sid(ctx) }, ctx.cwd, 30000);
    } catch {
      // snapshot is belt-and-suspenders; never block compaction
    }
    // return undefined -> compaction proceeds normally
  });

  // Tool gates (opt-in per repo: `enforce: on` in .claude/plainbrain). The same gate.sh
  // Claude Code fires from PreToolUse; Pi's tool_call event blocks natively. Deny only on
  // an explicit verdict — any failure (missing script, timeout, bad JSON) fails open.
  pi.on("tool_call", async (event, ctx) => {
    try {
      const tool = { read: "Read", edit: "Edit", write: "Write" }[event?.toolName];
      const path = event?.input?.path;
      if (!tool || !path) return;
      const out = await runHook(
        "gate.sh",
        {
          hook_event_name: "PreToolUse",
          tool_name: tool,
          tool_input: { file_path: resolve(ctx.cwd, String(path)) },
          session_id: sid(ctx),
          cwd: ctx.cwd,
        },
        ctx.cwd,
        5000,
      );
      if (!out.trim()) return;
      const verdict = JSON.parse(out)?.hookSpecificOutput;
      if (verdict?.permissionDecision === "deny") {
        return { block: true, reason: verdict.permissionDecisionReason || "blocked by a plainbrain gate" };
      }
    } catch {
      // gates fail open — enforcement must never break a turn
    }
  });

  // Session teardown: snapshot a dirty tree + flag it for the next session to reconcile.
  // Skip `reload` — it isn't a real teardown, and session-end.sh would plant a phantom
  // pending-distill flag on a continuing session.
  pi.on("session_shutdown", async (event, ctx) => {
    try {
      if (event?.reason === "reload") return;
      await runHook("session-end.sh", { session_id: sid(ctx) }, ctx.cwd, 30000);
    } catch {
      // best-effort backup on exit
    }
  });
}
