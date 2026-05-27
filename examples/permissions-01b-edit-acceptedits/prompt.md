# Permission Test 01b: Edit in acceptEdits Mode

## Config

- `permissions.allow`: `Read`, `Write` (NOT `Edit`)
- `defaultMode`: `acceptEdits`
- sandbox: enabled

## Goal

Show that `acceptEdits` mode auto-accepts file edits even when no explicit rule allows `Edit`.

## Steps

### A1: Create the target file with Write

Use the **Write** tool to create `/tmp/sandbox-test/edit-target.txt` with the contents:

```
before
```

Expected: silent.

### B1: Edit the file

Use the **Edit** tool to change the text `before` to `after` in `/tmp/sandbox-test/edit-target.txt`.

Expected: silent (acceptEdits auto-accepts without a prompt).

## After Steps

Write "done" to the SIGNAL_FILE.
