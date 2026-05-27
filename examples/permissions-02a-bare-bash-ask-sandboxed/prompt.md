# Permission Test 02a: Bare Bash in ask — Sandboxed Baseline

## Config

- `sandbox.enabled: true`, `autoAllowBashIfSandboxed: true`
- `permissions.ask: [Bash]` — bare Bash rule, no pattern

## Goal

Validate the baseline half of the escape-hatch workaround (from anthropics/claude-code#34315): bare `Bash` in the `ask` list does NOT fire for sandboxed commands. Sandboxed-safe commands should still auto-allow silently.

If this test prompts, the workaround has changed behavior and would be too noisy to recommend.

## Steps

### A1: Simple sandboxed read

Run this command using the **Bash** tool:

```
ls /tmp/sandbox-test
```

Expected: **silent** — auto-allowed by `autoAllowBashIfSandboxed`. The bare `Bash` ask rule should not override the sandboxed auto-allow path.

### A2: Sandboxed write (inside allowed path)

Run this command using the **Bash** tool:

```
touch /tmp/sandbox-test/ask-baseline-test.txt && echo done
```

Expected: **silent** — write inside sandbox allowWrite, compound all-safe, auto-allowed.

### A3: Another sandboxed read

Run this command using the **Bash** tool:

```
cat /tmp/sandbox-test/README.md 2>&1 | head -3
```

Expected: **silent**.

## After All Steps

Write "done" to the SIGNAL_FILE.
