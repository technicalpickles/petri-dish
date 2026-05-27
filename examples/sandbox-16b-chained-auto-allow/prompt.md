# Session 16b: Chained Bash Commands with Auto-Allow On

## Sandbox Config

Sandbox enabled, `autoAllowBashIfSandboxed: true`. With auto-allow on, Bash commands running under the sandbox shouldn't surface a permission prompt at all — they're allowed because the sandbox itself is the safety boundary.

## Goal

Close the open question from sandbox-16: **does auto-allow actually skip the permission prompt layer end-to-end, or does Claude Code still log `PermissionRequest` events (and still compute possibly-misfiring `permission_suggestions`)?**

If `PermissionRequest` events still fire, then the misfiring permission-suggestion machinery from sandbox-16 is still running, even if the user never sees the UI for it. If they don't fire, then auto-allow fully short-circuits that whole path.

## Protocol

Follow the test protocol from the preamble. Run each command, report the result, output a RESULT line, move to the next. Run commands verbatim — do not split compound commands.

Setup:

```
SETUP: mkdir -p /tmp/chained-bash-probe && cd /tmp/chained-bash-probe && git init -q
```

## Test Commands

Identical to sandbox-16, so results can be compared directly.

### Group A: Baseline single commands (control)

```
A1: echo hi
A2: git -C /tmp/chained-bash-probe status
```

### Group B: `cd &&` chains — the shape that misfired in sandbox-16

```
B1: cd /tmp/chained-bash-probe && echo hi
B2: cd /tmp/chained-bash-probe && git status
```

### Group C: non-`cd` chain

```
C1: echo a && echo b
```

## What to Observe

Same as sandbox-16. Whether any `PermissionRequest` event fires, and if so, what `permission_suggestions` look like — everything will be read from the hook log after the run.

## After All Tests

Write "done" to the SIGNAL_FILE.
