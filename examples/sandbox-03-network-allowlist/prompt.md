# Session 3: Network Domain Allowlist

## Sandbox Config

This environment has `allowedDomains` set to: `api.github.com`, `*.npmjs.org`, `registry.yarnpkg.com`. Everything else should either be blocked or prompt.

## Goal

Understand how `allowedDomains` interacts with the sandbox proxy. Do unlisted domains get blocked silently or prompt? Does wildcard matching work? Where does approval state persist?

## Protocol

Follow the test protocol from the preamble. Run each command, report the result, output a RESULT line, move to the next.

## Test Commands

### Group A: Explicitly Allowed Domains

```
A1: curl -s https://api.github.com/zen
A2: curl -s https://registry.npmjs.org/left-pad | head -c 200
A3: curl -s https://registry.yarnpkg.com/left-pad | head -c 200
```

### Group B: Wildcard Match Testing

```
B1: curl -s https://www.npmjs.org | head -c 200
B2: curl -s https://replicate.npmjs.org | head -c 200
```

### Group C: Not in Allowlist

```
C1: curl -s -m 5 https://example.com
C2: curl -s -m 5 https://httpbin.org/get
C3: curl -s -m 5 https://pypi.org/simple/ | head -c 200
```

### Group D: Edge Cases

```
D1: curl -s -m 5 https://github.com/ | head -c 200
D2: curl -s -m 5 https://raw.githubusercontent.com/anthropics/claude-code/main/README.md | head -c 200
D3: curl -s -m 5 http://api.github.com/zen
D4: curl -s -m 5 https://1.1.1.1
```

### Group E: Package Manager Integration

```
E1: npm view left-pad version
E2: pip install --dry-run requests 2>&1 | head -20
```

### Group F: WebFetch Tool (same URLs, different tool)

Use the **WebFetch tool** (NOT Bash, NOT curl) for each of these. This tests whether the sandbox network restrictions apply to built-in tools or only to Bash subprocesses.

```
F1: WebFetch https://api.github.com/zen
F2: WebFetch https://registry.npmjs.org/left-pad
F3: WebFetch https://www.npmjs.org
F4: WebFetch https://example.com
F5: WebFetch https://httpbin.org/get
F6: WebFetch https://github.com/
```

## After All Tests

Write "done" to the SIGNAL_FILE.
