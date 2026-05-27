# Session 6: Custom Write Paths

## Sandbox Config

This environment adds custom write paths: `//tmp/sandbox-build` (absolute) and `./local-output` (relative to cwd). Tests how path prefix notation works and whether user + project scope settings merge.

## Goal

Understand the `allowWrite` path prefix system (`//` for absolute, `./` for relative, `~/` for home). Test if writes outside allowed paths are blocked. See how relative paths resolve.

## Protocol

Follow the test protocol from the preamble. Run each command, report the result, output a RESULT line, move to the next.

## Test Commands

### Group A: Allowed Write Paths

```
A1: echo "test" > /tmp/sandbox-build/out.txt
A2: cat /tmp/sandbox-build/out.txt
A3: mkdir -p local-output && echo "test" > local-output/out.txt
A4: cat local-output/out.txt
```

### Group B: Default Allowed (in-project)

```
B1: echo "in-project write" > test-local.txt
B2: cat test-local.txt
B3: rm test-local.txt
```

### Group C: Denied Write Paths

```
C1: echo "test" > /tmp/not-sandbox-build/out.txt
C2: echo "test" > ~/sandbox-test-denied.txt
C3: echo "test" > /tmp/sandbox-build-extra/out.txt
C4: echo "test" >> ~/.bashrc
```

### Group D: Path Resolution Edge Cases

```
D1: echo "test" > /private/tmp/sandbox-build/out2.txt
D2: echo "test" > ./local-output/subdir-test.txt
D3: mkdir -p local-output/nested && echo "test" > local-output/nested/deep.txt
```

D1 tests whether `/tmp` -> `/private/tmp` symlink resolution affects the `//tmp/sandbox-build` rule.
D2 tests explicit `./` prefix.
D3 tests whether subdirectories of allowed paths are also allowed.

### Group E: Cleanup

```
E1: rm -f /tmp/sandbox-build/out.txt /tmp/sandbox-build/out2.txt 2>&1
E2: rm -rf local-output 2>&1
```

## After All Tests

Write "done" to the SIGNAL_FILE.
