# petri-dish

A petri-dish for agentic coding experiments. Keep your cultures in your lab; load them into a dish to see how they grow.

## Why

Your `~/.claude/` is production. There's no staging copy of it, no rollback if a hook misbehaves or a plugin clobbers your settings. [I've written about this.](https://pickles.dev/dot-claude-is-production/) `CLAUDE_CONFIG_DIR` gets you a sandbox; petri-dish gets you reproducible experiments inside one.

A **culture** is one experiment: a `config.yml` + `prompt.md` pair. A **petri-dish** is what runs it. Each dish is isolated via [cenv](https://github.com/technicalpickles/cenv) so the experiment never touches your real config, and hooks injected into the dish observe the run from inside without disturbing it.

## What it does

`petri-dish run <culture>` boots an isolated cenv environment, injects PreToolUse/PostToolUse/PermissionRequest hooks, runs Claude Code against your prompt, and correlates the event log into a structured results file.

## Requirements

- Ruby >= 3.2
- [cenv](https://github.com/technicalpickles/cenv) for environment isolation
- tmux
- The Claude Code CLI (`claude`)

## Install

```
gem install petri-dish-lab
```

That puts `petri-dish` on your PATH. (The gem has a `-lab` suffix because `petri_dish` was already taken on rubygems; the CLI stays `petri-dish`.)

### Without setting up Ruby

If you don't want to deal with a Ruby toolchain, use [rv](https://github.com/spinel-coop/rv). It manages an isolated Ruby per tool and installs one for you if you don't have one.

```
brew install rv
rv tool install petri-dish-lab
```

For one-off invocation without touching shell init:

```
rv tool run --from petri-dish-lab petri-dish list
```

For the `petri-dish` binary on your PATH, follow `rv shell <your-shell>` to wire rv into your shell.

### From source

```
git clone https://github.com/technicalpickles/petri-dish.git
cd petri-dish
gem build petri-dish.gemspec
gem install petri-dish-lab-0.1.0.gem
```

## Quick start

```
mkdir my-lab && cd my-lab
mkdir -p cultures/my-first-culture
# write cultures/my-first-culture/config.yml and prompt.md
petri-dish setup my-first-culture
petri-dish run my-first-culture
petri-dish results my-first-culture
```

By default, petri-dish looks for cultures in `./cultures/` relative to your current directory. Override with `--cultures-dir <path>` or `PETRIDISH_CULTURES_DIR`.

To explore the bundled examples, from the cloned petri-dish repo:

```
petri-dish run --cultures-dir examples sandbox-01-baseline
```

## How it works

1. **Environment.** Each culture gets its own cenv environment with specific settings (sandbox config, permissions, plugins). Nothing touches your `~/.claude/`.
2. **Hooks.** PreToolUse, PostToolUse, and PermissionRequest hooks are injected into the dish to log events and auto-handle permission prompts.
3. **Prompt.** A markdown prompt tells Claude what commands to run and what to observe.
4. **Results.** Hook event logs are correlated into structured results (prompted vs silent, timing, outcomes).

## CLI reference

```
Usage: petri-dish <command> [options]

Commands:
  run <culture> [--deny] [--debug] [--keep] [--cultures-dir DIR]
  list                    List available cultures
  results [culture]       Show past results
  setup [culture]         Create environments
  setup --clean [culture] Tear down environments
  help                    Show this help
```

## Adding a culture

Each culture directory needs two files:

```
cultures/my-culture/
  config.yml
  prompt.md
```

See `examples/` for working configs. The schema:

```yaml
name: my-culture
description: "One-line description"

environment:
  name: test-my-culture
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

For a longer reference, including prompt-shape conventions, cell discipline (baseline cells, multi-run averaging, A/B variants), preamble selection, and the brittle bits to watch for, see [`claude-plugin/skills/petri-dish/references/authoring-cultures.md`](claude-plugin/skills/petri-dish/references/authoring-cultures.md).

If you use Claude Code, the [companion plugin](claude-plugin/README.md) ships that same reference as a skill so an agent can author cultures with the discipline already in working memory.

## Examples included

- `sandbox-*`: probes of Claude Code's sandbox behavior across filesystem, network, IPC, and escape-hatch settings.
- `permissions-*`: how permission prompts behave under different settings.
- `guidance-*`: prompt-layer interventions for sandbox-safe path selection.
- `parser-*`: Claude Code's permission parser boundary cases.

## License

MIT. See LICENSE.
