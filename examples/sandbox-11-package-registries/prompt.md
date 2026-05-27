# Session 11: Package Registry Access via npx

## Sandbox Config

**Part A:** Baseline sandbox, no `allowedDomains` configured. Nothing pre-allowed for network.

**Part B:** `allowedDomains` includes package registries: `registry.npmjs.org`, `*.npmjs.org`, `pypi.org`, `*.pypi.org`, `files.pythonhosted.org`, `rubygems.org`, `*.rubygems.org`.

## Goal

Determine how the sandbox handles package registry network access when triggered by npx. Does it prompt, pass silently, or break?

## Protocol

Follow the test protocol from the preamble. Run each command, report the result, output a RESULT line, move to the next.

## Test Command

```
npx --yes cowsay@1.6.0 "sandbox test"
```

## After the Test

Output the results table and note:
1. Did it work end-to-end?
2. Was the registry domain prompted or silent?
3. How many prompts did the invocation trigger?

## After All Tests

Write "done" to the SIGNAL_FILE.
