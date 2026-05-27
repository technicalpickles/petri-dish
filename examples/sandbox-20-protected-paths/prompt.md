# Session 20: Hardcoded Protected Paths

## Sandbox Config

This is a THREE-PART probe. The probe is identical across all three; only the sandbox config differs.

- **Part A** (sandbox-20-protected-paths): Default sandbox, no allowWrite override
- **Part B** (sandbox-20b-protected-paths-allowwrite): Default + explicit `sandbox.filesystem.allowWrite` for the suspected protected paths
- **Part C** (sandbox-20c-protected-paths-sandbox-off): `sandbox.enabled: false` (control)

You don't need to know which part you're running. Just run the probe.

## Goal

`.claude/rules/sandbox-git-writes.md` claims Claude Code blocks writes to a hardcoded set of paths under any cwd subtree, even when those denies aren't in the visible sandbox config:

- `.claude/agents/*`
- `.claude/commands/*`
- `.vscode/*`
- `.mcp.json`
- `.gitmodules`

Open question (bean gt-j27u): does explicit `sandbox.filesystem.allowWrite` override these hardcoded denies, or do hardcoded denies always win?

We probe these paths plus a few neighbors (`.claude/skills`, `.claude/settings*.json`, `.git/config`) and a few sibling controls.

## Protocol

Follow the test protocol from the preamble. Run each command, report the result, output a RESULT line, move to the next.

## Pre-flight Cleanup

Wipe state from prior runs. These deletes may themselves fail under sandbox; that's information, just record and continue.

```
P1: rm -rf .claude/agents .claude/commands .claude/hooks .vscode .mcp.json .gitmodules sibling.txt some-dir 2>&1
P2: rm -f .claude/skills/probe.md .claude/random-probe.md 2>&1
```

## Probe

### Group A: Documented hardcoded denies

```
A1: mkdir -p .claude/agents && echo "test" > .claude/agents/probe.md 2>&1
A2: mkdir -p .claude/commands && echo "test" > .claude/commands/probe.md 2>&1
A3: mkdir -p .vscode && echo "test" > .vscode/settings.json 2>&1
A4: echo "test" > .mcp.json 2>&1
A5: echo "test" > .gitmodules 2>&1
```

### Group B: Other Claude paths (some appear in visible denyWithinAllow elsewhere)

```
B1: mkdir -p .claude/skills && echo "test" > .claude/skills/probe.md 2>&1
B2: mkdir -p .claude/hooks && echo "test" > .claude/hooks/probe.sh 2>&1
B3: echo '{}' > .claude/settings.json 2>&1
B4: echo '{}' > .claude/settings.local.json 2>&1
```

### Group C: Git internals

```
C1: echo "# probe" >> .git/config 2>&1
C2: echo "#!/bin/sh" > .git/hooks/probe-hook 2>&1
```

### Group D: Sanity controls (should succeed under default sandbox)

```
D1: echo "test" > sibling.txt 2>&1
D2: mkdir -p .claude && echo "test" > .claude/random-probe.md 2>&1
D3: mkdir -p some-dir && echo "test" > some-dir/probe.md 2>&1
```

## After All Tests

Write "done" to the SIGNAL_FILE.
