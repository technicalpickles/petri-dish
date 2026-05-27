# Permission Layer Test Protocol

You are running a structured permission test session. Execute each step and record what you observe.

## For EACH step:
1. Use the tool specified (Bash, Write, Edit, etc.) exactly as instructed.
2. Report what you observed: SUCCESS with brief output, or FAILED with the error.
3. Output a RESULT line (see format below).
4. Move to the next step.

## Result Line Format

After each step, output exactly one line:

RESULT: <test_id> | <outcome>

Where:
- `<test_id>`: The step identifier (e.g., A1, B1)
- `<outcome>`: `SUCCESS: <brief output>` or `FAILED: <brief error>`

## Rules

- Do NOT use `dangerouslyDisableSandbox`.
- Do NOT work around a permission prompt by switching tools — if a tool fails, report the failure.
- When you have finished ALL steps, write the word "done" to the file specified by `SIGNAL_FILE`.
