# Session 13: Parser Boundary Test

## Sandbox Config

Sandbox enabled, `autoAllowBashIfSandboxed: true`. Commands the parser classifies as `simple` AND read-only will auto-allow silently. Complex or non-read-only commands will prompt.

## Goal

Validate the command parser analysis against real behavior. We know the parser uses tree-sitter to walk bash ASTs and classify commands as `simple` or `too-complex`. This test probes the boundary: for loops, if/then, subshells, command substitution, brace expansion, variable expansion, and more.

The "interesting" tests are C1-C2, D1-D2, E1-E2 (loops/conditionals/subshells with read-only bodies). The parser walks these in interactive mode, but it's unclear whether they come out as `simple`.

## Protocol

Follow the test protocol from the preamble. Run each command, report the result, output a RESULT line, move to the next.

## Test Commands

### Group A: Simple commands (baseline, should auto-allow)

```
A1: ls -la /tmp/sandbox-test
```

```
A2: echo hello world
```

```
A3: cat /dev/null
```

### Group B: Pipelines (walked, should auto-allow if read-only)

```
B1: echo hello | grep h
```

```
B2: ls -la | head -5
```

```
B3: cat /dev/null | wc -l
```

### Group C: For loops (walked in interactive mode)

```
C1: for f in a.txt b.txt c.txt; do echo $f; done
```

```
C2: for i in 1 2 3; do echo "item $i"; done
```

```
C3: for f in *.txt; do cat $f; done
```

### Group D: If/then (walked in interactive mode)

```
D1: if [[ -f /tmp/sandbox-test/foo ]]; then echo exists; fi
```

```
D2: if true; then echo yes; else echo no; fi
```

### Group E: Subshells (walked in interactive mode)

```
E1: (echo hello)
```

```
E2: (cd /tmp && ls)
```

### Group F: Command substitution (always too-complex)

```
F1: echo $(whoami)
```

```
F2: echo $(ls /tmp)
```

### Group G: Brace expansion (always too-complex)

```
G1: echo {1..5}
```

```
G2: echo file-{a,b,c}.txt
```

### Group H: Process substitution (always too-complex)

```
H1: cat <(echo hello)
```

### Group I: Compound statements and other constructs

```
I1: { echo a; echo b; }
```

```
I2: echo hello; echo world
```

### Group J: Variable expansion

```
J1: echo $HOME
```

```
J2: echo $PATH
```

```
J3: echo $MY_CUSTOM_VAR
```

### Group K: Non-read-only commands (simple parse, but should prompt)

```
K1: touch /tmp/sandbox-test/testfile
```

```
K2: mkdir -p /tmp/sandbox-test/testdir
```

## After All Tests

Write "done" to the SIGNAL_FILE.
