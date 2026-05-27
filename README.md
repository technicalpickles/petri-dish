# Petri

Isolated, repeatable Claude Code experiments. The [cenv](https://github.com/technicalpickles/cenv) environment is the dish; petri is the technician.

## What it does

Petri runs a Claude Code session inside an isolated cenv environment, injects hooks to log every tool call and permission prompt, and correlates the events into structured results. You write a small `config.yml` and a `prompt.md` for each experiment, then `petri run <name>` to execute it.

## Requirements

- Ruby >= 3.2
- [cenv](https://github.com/technicalpickles/cenv) for environment isolation
- tmux
- The Claude Code CLI (`claude`)

## Install

```
gem install petri
```

## Quick start

```
mkdir my-experiments && cd my-experiments
mkdir -p petri/my-first-test
# write petri/my-first-test/config.yml and prompt.md
petri setup my-first-test
petri run my-first-test
petri results my-first-test
```

By default, petri looks for tests in `./petri/` relative to your current directory. Override with `--tests-dir <path>` or `PETRI_TESTS_DIR`.

To explore the bundled examples without writing your own, clone the repo and run from there:

```
git clone https://github.com/technicalpickles/petri.git
cd petri
petri run --tests-dir examples sandbox-01-baseline
```

## How it works

1. **Environment**: Each test gets its own cenv environment with specific settings (sandbox config, permissions, plugins).
2. **Hooks**: PreToolUse, PostToolUse, and PermissionRequest hooks are injected to log events and auto-handle permission prompts.
3. **Prompt**: A markdown prompt tells Claude what commands to run and what to observe.
4. **Results**: Hook event logs are correlated into structured results (prompted vs silent, timing, outcomes).

## CLI reference

```
Usage: petri <command> [options]

Commands:
  run <test> [--deny] [--debug] [--keep] [--tests-dir DIR]
  list                    List available tests
  results [test]          Show past results
  setup [test]            Create environments
  setup --clean [test]    Tear down environments
  help                    Show this help
```

## Adding a test

Each test directory needs two files:

```
petri/my-test/
  config.yml
  prompt.md
```

See `examples/` for working configs. The schema:

```yaml
name: my-test
description: "One-line description"

environment:
  name: test-my-test
  plugins: []
  settings:
    sandbox:
      enabled: true
    permissions:
      allow:
        - Read
        - Write

runtime:
  work_dir: /tmp/sandbox-test
  preamble: lib/preambles/sandbox.md   # optional, resolves to a bundled or local preamble
  inject_results_file: true
  timeout: 300

prompt_mode: accept   # or "deny"
```

## Examples included

- `sandbox-*`: probes of Claude Code's sandbox behavior across filesystem, network, IPC, and escape-hatch settings.
- `permissions-*`: how permission prompts behave under different settings.
- `guidance-*`: prompt-layer interventions for sandbox-safe path selection.
- `parser-*`: Claude Code's permission parser boundary cases.

## License

MIT. See LICENSE.
