# Session 5: Network Lockdown (Managed Domains Only)

## Sandbox Config

This environment simulates enterprise lockdown: `allowManagedDomainsOnly: true` with only `api.github.com`, `*.anthropic.com`, `*.amazonaws.com` allowed. Everything else should be blocked with NO prompt (the point of managed-only is no user bypass).

Note: `allowManagedDomainsOnly` is documented as a managed-settings-only key. It may not work from user settings. Finding out is part of the test.

## Goal

Test whether managed lockdown works outside managed settings. Understand what the user experience is when domains are silently blocked (no prompt, no override). See what error the process gets.

## Protocol

Follow the test protocol from the preamble. Run each command, report the result, output a RESULT line, move to the next.

## Test Commands

### Group A: Allowed Domains

```
A1: curl -s https://api.github.com/zen
A2: curl -s https://docs.anthropic.com/ | head -c 200
```

### Group B: Blocked Domains (should fail silently)

```
B1: curl -s -m 10 https://example.com
B2: curl -s -m 10 https://httpbin.org/get
B3: curl -s -m 10 https://registry.npmjs.org/left-pad | head -c 200
B4: curl -s -m 10 https://rubygems.org
```

(The `-m 10` timeout prevents hanging if the proxy just drops the connection.)

### Group C: Package Managers (should fail)

```
C1: npm view left-pad version 2>&1
C2: pip install --dry-run requests 2>&1 | head -20
```

### Group D: Does Claude Code Still Work?

If you got this far, Claude Code itself is working. But test explicit API-related domains:

```
D1: curl -s -m 10 https://bedrock-runtime.us-west-2.amazonaws.com/ 2>&1 | head -c 200
```

## After All Tests

Write "done" to the SIGNAL_FILE.
