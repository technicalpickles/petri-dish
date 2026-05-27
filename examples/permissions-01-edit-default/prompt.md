# Permission Test 01: Edit in Default Mode

## Config

- `permissions.allow`: `Read`, `Write` (NOT `Edit`)
- `defaultMode`: unset (default)
- sandbox: enabled

## Goal

Show that Edit on a plain file prompts the user when no rule auto-allows it and no mode auto-accepts.

## Steps

### A1: Create the target file with Write

Use the **Write** tool to create `/tmp/sandbox-test/edit-target.txt` with the contents:

```
before
```

Expected: silent (Write is in allow list).

### B1: Edit the file

Use the **Edit** tool to change the text `before` to `after` in `/tmp/sandbox-test/edit-target.txt`.

Expected: permission prompt. Sidecar will auto-accept.

## After Steps

Write "done" to the SIGNAL_FILE.
