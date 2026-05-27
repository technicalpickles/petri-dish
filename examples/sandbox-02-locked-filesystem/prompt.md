# Session 2: Locked Down Filesystem

## Sandbox Config

Sandbox with `denyRead: ["~/sandbox-test-sensitive"]` and `allowRead: ["~/sandbox-test-sensitive/public"]`. Tests granular filesystem read controls and the deny/allow override interaction.

## Prerequisites

These directories should exist (setup.sh creates them):
- `~/sandbox-test-sensitive/public/readme.txt` (contains "public data")
- `~/sandbox-test-sensitive/private/secrets.txt` (contains "SECRET_KEY=abc123")

## Goal

Test how denyRead and allowRead interact. Does allowRead inside a denyRead region work? Does `ls` on a denied directory leak filenames? Can `find` traverse denied dirs? What error does the process see?

## Protocol

Follow the test protocol from the preamble. Run each command, report the result, output a RESULT line, move to the next.

## Test Commands

### Group A: Read Denial

```
A1: cat ~/sandbox-test-sensitive/private/secrets.txt 2>&1
A2: cat ~/sandbox-test-sensitive/also-secret.txt 2>&1
```

These should be denied (inside denyRead region, not in allowRead).

### Group B: Read Allow Override

```
B1: cat ~/sandbox-test-sensitive/public/readme.txt 2>&1
B2: ls ~/sandbox-test-sensitive/public/ 2>&1
```

These should work (allowRead overrides denyRead for this subdir).

### Group C: Directory Listing of Denied Path

```
C1: ls ~/sandbox-test-sensitive/ 2>&1
C2: ls -la ~/sandbox-test-sensitive/ 2>&1
```

Key question: does `ls` on the denied directory show filenames (metadata leak) or fail entirely?

### Group D: find Traversal

```
D1: find ~/sandbox-test-sensitive -name "*.txt" 2>&1
D2: find ~/sandbox-test-sensitive/public -name "*.txt" 2>&1
```

D1 tests whether find can traverse the denied root to discover the allowed subdirectory.
D2 tests whether targeting the allowed subdirectory directly works.

### Group E: Read Tool vs Bash Comparison

For this group, use the Read tool (not Bash) to read these files. Note whether the behavior differs from the Bash `cat` results above.

```
E1: (use Read tool) ~/sandbox-test-sensitive/private/secrets.txt
E2: (use Read tool) ~/sandbox-test-sensitive/public/readme.txt
```

### Group F: Write Denial

```
F1: echo "test" > ~/sandbox-test-sensitive/write-test.txt 2>&1
F2: echo "test" > ~/sandbox-test-sensitive/public/write-test.txt 2>&1
```

allowRead doesn't imply allowWrite. Both should fail.

### Group G: Non-Denied Reads (sanity check)

```
G1: cat /etc/hosts 2>&1 | head -3
G2: cat ~/.claude/settings.json 2>&1 | head -3
```

These should work normally (not in denyRead).

## After All Tests

Write "done" to the SIGNAL_FILE.
