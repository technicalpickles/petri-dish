# Session 16: Chained Bash Commands and Permission Prompts

## Sandbox Config

Sandbox enabled, `autoAllowBashIfSandboxed: false`. No Bash tool pre-allowed. Every Bash command surfaces a permission prompt, and the hook log records what substring Claude Code asked permission for.

## Goal

Validate the long-standing claim that compound Bash commands joined with `&&` misfire the permission prompt — specifically that `cd /path && git commit` prompts the user for `cd:*` instead of the actually-risky `git commit`. The claim predates several Claude Code versions; we want first-hand evidence under the current build.

The hypothesis the old CLAUDE.md rule rested on:

> Compound commands like `cd /path && git add file && git commit` cause permission prompts to misfire, prompting for `cd:*` instead of the actual command.

What we want from this run: the exact prompt string (tool + command pattern) that the hook captures for each shape below.

## Protocol

Follow the test protocol from the preamble. Run each command, report the result, output a RESULT line, move to the next. Do NOT break a compound command up into multiple Bash calls — run it verbatim.

Before starting, ensure `/tmp/chained-bash-probe` exists and contains a git repo:

```
SETUP: mkdir -p /tmp/chained-bash-probe && cd /tmp/chained-bash-probe && git init -q
```

## Test Commands

### Group A: Baseline single commands (control)

```
A1: echo hi
A2: git -C /tmp/chained-bash-probe status
```

### Group B: `cd &&` chains — the old rule's target shape

```
B1: cd /tmp/chained-bash-probe && echo hi
B2: cd /tmp/chained-bash-probe && git status
```

### Group C: non-`cd` chains — isolates whether `cd` is special

```
C1: echo a && echo b
```

## What to Observe

For each command, note:

- Whether a permission prompt fired at all (auto-allow may catch it).
- If prompted, the exact command pattern shown in the prompt (the RESULT line should reflect both outcome and the prompt string Claude observed).

The harness hook log will independently record `PermissionRequest` events for the audit; the RESULT lines are the human-readable confirmation.

## After All Tests

Write "done" to the SIGNAL_FILE.
