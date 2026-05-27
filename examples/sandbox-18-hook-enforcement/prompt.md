# Session 18: Hook Enforcement

## Sandbox Config

Sandbox enabled, `autoAllowBashIfSandboxed: true`. A PreToolUse hook is installed that denies any Bash command starting with `curl `. All other commands should flow normally.

## Goal

Show that a PreToolUse hook can deny a command regardless of what permission rules, sandbox mode, or auto-mode would otherwise decide. The hook is the final authority.

## Test Commands

### Group A: Commands the hook allows (baseline)

```
A1: ls -la
```

```
A2: echo "hello from a non-curl command"
```

### Group B: Commands the hook denies

```
B1: curl -s https://api.github.com/zen
```

The sandbox and auto-allow would both permit this curl silently. The hook overrides and denies it. Report the error you see.

### Group C: Close variants (same binary, different casing/argv)

```
C1: /usr/bin/curl -sI https://example.com
```

The hook pattern is `^curl`, so this invocation (using the full path) should NOT match and should run normally. This demonstrates that hook policy is only as precise as its regex.

## After All Tests

Write "done" to the SIGNAL_FILE.
