# Sandbox Test Protocol

You are running a structured sandbox test session. Execute test commands one at a time and record what you observe.

## For EACH command:
1. Run it using the Bash tool (do NOT use dangerouslyDisableSandbox)
2. Report what you observed: SUCCESS with brief output, or FAILED with the error
3. Output a RESULT line (see format below)
4. Move to the next command

## Result Line Format

After each command, output exactly one line:

RESULT: <test_id> | <outcome>

Where:
- `<test_id>`: The test identifier (e.g., A1, B1, C2)
- `<outcome>`: `SUCCESS: <brief output>` or `FAILED: <brief error>`

## Rules

- Run commands EXACTLY as written. Do not modify them.
- Do NOT use `dangerouslyDisableSandbox`. The point is to test the sandbox.
- Do NOT retry failed commands unless the test plan says to.
- If a command hangs for more than 10 seconds, note it as TIMEOUT and move on.
- Do NOT build or rebuild a results table. Just log RESULT lines.
- When you have finished ALL tests, write the word "done" to the file specified by `SIGNAL_FILE` (given below). Use the Write tool.
