# Authoring cultures

A *culture* is one experiment in a petri-dish: a `config.yml` and `prompt.md` pair that describes the Claude Code session to set up and what to ask it. This guide is for someone (or some agent) writing a new culture. It distills the discipline learned from the sandbox-behavior and LSP activation probes into one reference.

If you just want to copy a working shape, the `examples/` directory has 50+ cultures across four categories (sandbox, permissions, guidance, parser). This doc covers the reasoning behind those choices so a new culture isn't a guess.

## The two files

Every culture lives in its own directory under `cultures/` (or wherever `--cultures-dir` points):

```
cultures/my-culture/
  config.yml      # environment, settings, runtime
  prompt.md       # what Claude is asked to do
```

`petri-dish setup my-culture` reads `config.yml`, creates a [cenv](https://github.com/technicalpickles/cenv) environment, installs plugins, merges settings, runs prepare commands. `petri-dish run my-culture` launches Claude against `prompt.md` and writes results to `results/my-culture/<timestamp>/`. `petri-dish results my-culture` lists past runs.

## config.yml reference

Top-level keys are validated by `lib/petri_dish/config.rb`. Required: `name`, `description`, `environment`, `runtime`. The rest take sensible defaults.

```yaml
name: my-culture                            # must match directory name
description: "One-line summary"

environment:
  name: test-my-culture                     # cenv environment name (required)
  plugins:                                  # optional; empty means no plugins
    - marketplace: anthropics/claude-plugins-official
      plugin: ruby-lsp
  settings:                                 # merged into the cenv's settings.json
    sandbox:
      enabled: true
      autoAllowBashIfSandboxed: true
    permissions:
      allow:
        - Read
        - Write
        - Bash

runtime:
  work_dir: /tmp/my-culture                 # cwd Claude runs in; default "."
  preamble: lib/preambles/sandbox.md        # optional; resolves to a bundled or local file
  inject_results_file: true                 # append SIGNAL_FILE line to prompt; default true
  prepare:                                  # shell commands run before Claude launches
    - rm -rf /tmp/my-culture
    - git clone --depth=1 <url> /tmp/my-culture
  timeout: 480                              # per-run cap in seconds; default 300
  model: null                               # optional model override

prompt_mode: accept                         # "accept" or "deny"; default "accept"
```

A few fields earn extra notes.

**`environment.settings`** is pass-through. Petri does not validate its shape; whatever you put here gets merged into the cenv's `settings.json` and Claude Code consumes it. That means the full settings schema is available: sandbox config, permissions allow/deny, hooks (though petri installs its own), `extraKnownMarketplaces`, anything else. Refer to the [Claude Code settings docs](https://code.claude.com/docs/en/settings) for the full surface.

**`runtime.prepare`** runs in the cwd of the *culture directory* (not `work_dir`). Use it for any setup that has to happen before Claude launches: cloning a fixture repo, installing deps, seeding test data. If a `prepare` step needs the right tool versions (`bundle install`, `npm install`), prefix it with `mise trust . 2>/dev/null;`. The cenv's mise trust gets refreshed *after* prepare runs, so the first prepare step can see an untrusted `.mise.toml`. The realpath gotcha is documented in `runner.rb`.

**`prompt_mode: deny`** flips the permission-handler hook to deny every prompt. Use it when the question you're asking is "what happens when the user says no." Most cultures use `accept`.

## prompt.md structure

The prompt is two parts. An optional preamble (configured via `runtime.preamble`) and the main prompt body. Petri appends a `**SIGNAL_FILE: <path>**` line at the bottom so Claude knows where to write the completion marker. The signal file is how the runner knows the session is finished, not a fixed timeout.

Always end your prompt with an instruction along the lines of:

```
When you have finished, write the word "done" to the file specified by SIGNAL_FILE.
```

(If `inject_results_file: true`, the SIGNAL_FILE path is appended for you. The instruction in your prompt body still has to tell Claude what to *do* with it.)

## Designing the prompt

The prompt is what generates signal. A well-shaped prompt produces a results file you can grep in five seconds; a poorly-shaped one produces prose you have to read by hand.

### Make the answer parseable

If your probe asks Claude to record findings, give it a fixed block shape and ask for one block per question. The LSP probes use:

```
For each question, append a block to ./RESULTS.md with this shape:

## Q<N>: <short name>
Answer: <path:line>
Confidence: <high|medium|low>
Notes: <how you found it, which tool you used>

1. Definition. Where is `class FormatterFactory` defined?
2. Interface method signature. What is the full signature of ...
3. ...
```

Three things make this work. First, the questions are deliberately shaped for the capability you're probing (definition lookup, references, interface methods are LSP-shaped; pick analogous shapes for whatever you're testing). Second, the fixed `Q<N>` block makes `grep '^## Q'` a manifest. Third, the `Notes: <which tool you used>` line is what makes tool choice measurable. Without it you have to infer from the hook log; with it, Claude self-reports.

### Sequential, not batched

The phrase that does load-bearing work:

```
Work through them in order, one at a time, appending the block to RESULTS.md
immediately after you have the answer. Do not batch.
```

Without this, Claude tends to run all five greps in parallel and write the file at the end. The hook log then shows a wall of tool calls with no obvious mapping back to questions, and per-question timing disappears. The "one at a time" wording fixes that.

### Don't over-specify the protocol

If the question is "what does Claude do when asked X under settings Y," do not tell Claude *how* to do X. Let the tool choice be free; that's the signal. The guidance preamble (`lib/preambles/guidance.md`) is explicit about this:

> Perform the task as you normally would. Do NOT optimize for any specific tool, path, or pattern.

The sandbox and permissions preambles are the opposite: those probes are about whether a specific command succeeds under a specific setting, so the commands are dictated and the rule is "run exactly as written."

Match the preamble shape to the question. Free tool choice for activation probes; dictated commands for capability probes.

## Picking a preamble

Four preambles ship with the gem at `lib/preambles/`:

| Preamble        | Use when                                                                                                                              |
| --------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| `sandbox.md`    | Probing what the sandbox blocks and allows. Dictates commands, requires RESULT lines, forbids `dangerouslyDisableSandbox`.            |
| `permissions.md`| Probing permission-prompt behavior. Same RESULT line shape, forbids switching tools to work around a prompt.                          |
| `escape-hatch.md`| Probing the escape-hatch reflex. Like `sandbox.md` but allows `dangerouslyDisableSandbox` retries and records both attempts.         |
| `guidance.md`   | Probing tool/path choice or whether Claude reaches for a specific capability. Free-form: "complete the task naturally."               |

If none fit, set `preamble: null` or omit the field. Your `prompt.md` is then the full prompt, with `SIGNAL_FILE` appended.

You can also point `preamble:` at a local file in your culture dir (e.g. `cultures/my-culture/preamble.md`). Resolution order: relative to the culture dir first, then relative to the gem's `lib/`.

## Cell discipline

The number of runs and the variable being tested are not afterthoughts. They are the experiment.

### Start with a baseline

Every investigation needs a *baseline cell*: a culture where nothing is intervened on. For the LSP work, the baseline was "plugin installed, no preamble, default prompt" and it scored 0/5 LSP-usage across runs on all three languages. That zero is what made every later cell's number meaningful: cell 4a (SessionStart hook) at 4.6/5 isn't surprising in isolation, but as a delta from a baseline of 0, it's the signal.

Without a baseline, you're measuring against your assumptions instead of against reality.

### Differ on one variable

When you A/B two cells, change one thing. If you compare the inline-preamble cell to a SessionStart-hook cell, both should have the same plugin set, the same permissions, the same prompt body. Only the placement of the hint moves. That's how you isolate "where the hint lands matters" from "the hint itself does the work."

If two variables move at once, your comparison is muddier and your finding is correspondingly weaker. Three variables and you've lost the cell.

### Multi-run averaging

Claude is stochastic. A single 5/5 LSP-usage score doesn't generalize. Most LSP findings are based on five runs per cell, sometimes more. The variance is real:

- Inline preamble cell: ranged 3 to 5 across five runs, mean 4.6.
- `CLAUDE.md` cell: ranged 2 to 5, mean 3.6.
- PreToolUse-alone cell: ranged 0 to 2, mean 0.4.

Without multiple runs those numbers lie. Default to five; go higher when the spread is wide or the cell is close to a decision boundary.

### When a number surprises you, re-run

A single 1/5 on welcome2u Rust didn't become "rust-analyzer needs pre-indexing" until a re-run with `cachePriming.numThreads: 'physical'` pulled it back up to 3/5. Surprising results are usually one of two things: a real finding, or a setup problem (server crashed silently, fixture didn't seed, OAuth went stale mid-run). A second run separates them.

## What's brittle

Three failure modes show up enough to mention in the doc rather than letting each new culture author rediscover them.

### Stale cenv OAuth

cenv environments hold their own Claude credentials and they expire on whatever Anthropic's refresh cadence is. The runner has a 60-second startup deadline and a mid-session auth-error pattern matcher, but the fix is always the same: `cenv login <env-name>`, re-run. If a culture run starts cleanly and then dies with no obvious cause, check the transcript for `/login` or `API Error: 401`.

### Plugin marketplace names

cenv stores marketplaces under their canonical name from `marketplace.json`, which isn't always the slug derived from the source URL. Petri's installer walks `plugin marketplace list` to find the actual name and falls back to the slug. When this fails, plugin install succeeds but the plugin isn't loaded and Claude runs without it. Always confirm with a `/plugin list` check in the transcript when you're shipping a plugin-dependent probe.

### mise trust

cenv creates a fresh `~/.config/mise/trusted-configs`, so any `mise.toml` in the cloned repo needs trusting before tools resolve. The runner re-trusts after `prepare` runs, but a `prepare` step that itself depends on the right tool versions can fail before the re-trust. If you see "Config files are not trusted" in a `prepare` log, prefix the offending step with `mise trust . 2>/dev/null;`.

### Sandbox EPERMs in surprising places

Claude Code's sandbox blocks writes to a hardcoded list of paths regardless of `allowWrite` settings: `.claude/agents/*`, `.claude/commands/*`, `.vscode/*`, `.mcp.json`, `.gitmodules`, and shell dotfiles inside any cwd. If your culture writes to one of those (probably accidentally, e.g. via `prettier --write .` over a worktree), it'll EPERM. The fix is usually to scope the write more narrowly or, if the probe is *about* sandbox behavior, accept the EPERM as the finding.

## Authoring with an agent

This repo ships a Claude Code plugin (`claude-plugin/`) with a SKILL that points an agent at this doc. Install it via the [`pickled-claude-plugins`](https://github.com/technicalpickles/pickled-claude-plugins) marketplace:

```
claude plugin marketplace add technicalpickles/pickled-claude-plugins
claude plugin install petri-dish@pickled-claude-plugins
```

Once installed, Claude has the schema, prompt-shape guidance, cell discipline, and gotchas in working memory when you ask it to author a culture. Phrasings that land:

- "Write a petri-dish culture that probes whether Claude reaches for `<tool>` when asked to do `<task>`."
- "Add an A/B variant of `<existing-culture>` that flips `<one variable>`."
- "What's a sensible baseline cell for investigating `<question>`?"

If you're authoring by hand, the shortest path is to find an example in `examples/` that's shaped like what you want and copy it. The categories in the README map cleanly to common shapes (sandbox probes, permission probes, guidance probes, parser probes).

## Related docs

- [README.md](../README.md): install, CLI reference, quick start
- [CONTRIBUTING.md](../CONTRIBUTING.md): code style, PR conventions
- The `examples/` directory: working cultures across four categories
- [How the Claude Code probes are built](https://github.com/technicalpickles/pickletown/blob/main/projects/claude-test-harness/docs/2026-05-27-how-the-probes-are-built.md) (in pickletown): the longer essay this guide was distilled from, with the LSP-specific context that doesn't belong in the gem
