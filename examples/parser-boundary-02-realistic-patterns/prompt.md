# Session: Parser Bail List — Realistic Patterns

## Sandbox Config

Sandbox enabled, `autoAllowBashIfSandboxed: true`. The parser classifies commands before the sandbox auto-allow check. We want to know which realistic compound patterns hit a bail and prompt vs. stay silent.

## Goal

Validate parser behavior on compound patterns actually observed in guidance-01b-bash-* cases, plus a few targeted probes for specific hypotheses:

- **Category B (variable position):** Does `$VAR` in a redirect target vs. argument position matter? Does `$TMPDIR` behave differently from `$HOME`?
- **Category C (cd + write):** Does the documented path-resolution-bypass trigger actually fire? Variations with variable paths, literal paths, and nested mkdir+cd compounds.
- **Category D (for loops):** Do bare `$i` loop variables trigger simple_expansion?
- **Category E (env prefix):** Does leading `env` (bare, with assignment, or as prefix) prompt?

## Protocol

Follow the test protocol from the preamble. Run each command EXACTLY as written, report the result, output a RESULT line, move to the next.

## Test Commands

### Category B: Variable position

```
B1: echo $HOME
```

```
B2: echo $TMPDIR
```

```
B3: echo hello > $TMPDIR/foo.txt
```

### Category C: cd + write

```
C1: cd $TMPDIR && echo x > foo.txt
```

```
C2: cd /tmp/sandbox-test && echo x > foo.txt
```

```
C3: mkdir -p /tmp/sandbox-test/sub && cd /tmp/sandbox-test/sub && echo x > foo.txt
```

### Category D: for loops

```
D1: for i in 1 2 3; do echo $i; done
```

```
D2: for i in 1 2 3; do echo $i > /tmp/sandbox-test/log-$i.txt; done
```

### Category E: env prefix

```
E1: env
```

```
E2: env FOO=bar echo hello
```

```
E3: FOO=bar echo hello
```

## After All Tests

Write "done" to the SIGNAL_FILE.
