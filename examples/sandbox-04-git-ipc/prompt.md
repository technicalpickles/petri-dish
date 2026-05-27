# Session 4: Git Operations Under Sandbox

## Sandbox Config

Baseline sandbox: enabled, autoAllowBashIfSandboxed. No extra filesystem or network config. This tests what breaks with default settings.

## Goal

Git uses unix sockets (fsmonitor-daemon), Mach IPC (credential helpers, Security framework), and SSH agent sockets. This host has `core.fsmonitor = true` globally. Find out what git operations break, what errors appear, and whether they're hard failures or degraded-but-functional.

## Protocol

Follow the test protocol from the preamble. Run each command, report the result, output a RESULT line, move to the next.

## Test Commands

### Group A: Basic Read Operations

```
A1: git status
A2: git log --oneline -5
A3: git diff
A4: git branch -a
```

Note: watch stderr carefully. Git may succeed but print IPC warnings to stderr.

### Group B: fsmonitor Specifically

```
B1: git fsmonitor--daemon status
B2: git config --get core.fsmonitor
B3: git -c core.fsmonitor=false status
B4: git -c core.fsmonitor=true status
```

Compare B3 vs B4: does disabling fsmonitor eliminate any errors from Group A?

### Group C: Write Operations

```
C1: echo "sandbox test line" >> README.md
C2: git add README.md
C3: git commit -m "test commit from sandbox"
C4: git stash
C5: git stash pop
```

### Group D: Index and Reflog

```
D1: git reflog -3
D2: git rev-parse HEAD
D3: git update-index --refresh
```

### Group E: Network-Dependent Git

```
E1: ssh-add -l
E2: git ls-remote --heads origin 2>&1 | head -5
E3: gh auth status
```

### Group F: Git Config Access

```
F1: git config --global --list | head -20
F2: git config --global user.name
F3: git config --global user.email
F4: git config --global core.fsmonitor
```

## After All Tests

Write "done" to the SIGNAL_FILE.
