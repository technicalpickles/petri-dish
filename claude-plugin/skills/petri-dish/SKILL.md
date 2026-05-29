---
name: petri-dish
description: Use when authoring a petri-dish culture (Claude Code experiment), designing an A/B variant, picking a baseline cell, or shaping a probe prompt. Triggers on "write a culture", "petri-dish culture", "author a probe", "design an experiment for Claude Code", "A/B variant of <culture>", "baseline cell for <question>", or any task that produces a `config.yml` + `prompt.md` pair under `cultures/`. Also use when reasoning about whether a probe is well-shaped: multi-run discipline, structured result blocks, sequential-not-batched wording, preamble selection. Skip for running existing cultures (`petri-dish run`) and gem-internal code changes.
user_invocable: true
---

# Authoring petri-dish cultures

A *culture* is one petri-dish experiment: a directory under `cultures/` (or whatever `--cultures-dir` points at) containing `config.yml` and `prompt.md`. This skill is for shaping new cultures so they generate clean signal, not muddy prose.

The deep reference is [references/authoring-cultures.md](references/authoring-cultures.md) in the gem repo. Read it for the schema, full prompt-shape guidance, preamble inventory, cell discipline, and gotchas. The summary below is what to keep loaded while authoring.

## The shape

```
cultures/my-culture/
  config.yml      # environment, settings, runtime
  prompt.md       # what Claude is asked to do
```

`config.yml` minimum:

```yaml
name: my-culture
description: "One-line summary"

environment:
  name: test-my-culture
  plugins: []                  # or [{marketplace: ..., plugin: ...}]
  settings:                    # passed through to Claude Code settings.json
    sandbox: { enabled: true }
    permissions: { allow: [Read, Write, Bash] }

runtime:
  work_dir: /tmp/my-culture    # default "."
  preamble: lib/preambles/sandbox.md   # optional; null for no preamble
  prepare: []                  # shell commands run before Claude launches
  timeout: 300                 # seconds

prompt_mode: accept            # "accept" or "deny"
```

The schema is validated by `lib/petri_dish/config.rb` in the gem. `environment.settings` is pass-through and unvalidated; it accepts the full Claude Code settings surface.

## Prompt anatomy

Prompts are two parts: an optional preamble (resolved via `runtime.preamble`) and the body in `prompt.md`. Petri appends `**SIGNAL_FILE: <path>**` to the bottom; the body has to tell Claude to write "done" to that file when finished.

Two patterns that make prompts measurable:

**Structured Q-block format** when asking multiple questions:

```
## Q<N>: <short name>
Answer: <path:line>
Confidence: <high|medium|low>
Notes: <how you found it, which tool you used>
```

**Sequential-not-batched** wording:

```
Work through them in order, one at a time, appending the block to RESULTS.md
immediately after you have the answer. Do not batch.
```

Without that wording, Claude tends to run all calls in parallel and write at the end, which makes the hook log hard to map back to questions.

## Picking a preamble

| Preamble        | Use when                                                                  |
| --------------- | ------------------------------------------------------------------------- |
| `sandbox.md`    | Probing what the sandbox blocks/allows; dictates commands                 |
| `permissions.md`| Probing permission-prompt behavior under different settings               |
| `escape-hatch.md`| Probing the `dangerouslyDisableSandbox` reflex; records both attempts    |
| `guidance.md`   | Probing tool/path choice; free-form "complete the task naturally"        |

Free tool choice for activation probes (does Claude reach for the LSP?). Dictated commands for capability probes (does this command succeed under this setting?). Match the preamble shape to the question.

## Cell discipline

A *cell* is one specific configuration. To get findings out of a probe rather than vibes:

1. **Start with a baseline cell.** Nothing intervened on. That zero (or whatever it is) is what makes deltas meaningful.
2. **Differ on one variable per A/B.** Two variables moving at once muddies the comparison; three loses it.
3. **Run each cell five times.** Single runs lie. Real variance from the LSP work: inline preamble cell ranged 3-5 (mean 4.6); `CLAUDE.md` cell ranged 2-5 (mean 3.6).
4. **Re-run surprises.** Surprising results are usually either a real finding or a setup problem (server crashed, fixture missing, OAuth went stale). A second run separates them.

## Brittle bits to watch for

- **Stale cenv OAuth.** Cultures die with `API Error: 401` or `/login` in the transcript. Fix: `cenv login <env-name>`, re-run.
- **Plugin marketplace name quirks.** Plugin install reports success but `/plugin list` shows it missing. Confirm with a `/plugin list` check in the transcript for any plugin-dependent probe.
- **mise trust.** If a `prepare` step fails with "Config files are not trusted," prefix with `mise trust . 2>/dev/null;`. The cenv re-trusts *after* prepare.
- **Sandbox EPERMs on hardcoded paths.** `.claude/agents/*`, `.claude/commands/*`, `.vscode/*`, `.mcp.json`, `.gitmodules`, and shell dotfiles are blocked regardless of `allowWrite`. Scope writes narrowly or accept the EPERM as the finding.

## Where to start

- **New culture, similar to an existing one:** find an example in `examples/` shaped like what you want, copy the directory, edit.
- **New culture, novel shape:** read [references/authoring-cultures.md](references/authoring-cultures.md) start to finish, then draft `config.yml` and `prompt.md` together.
- **A/B variant:** copy the existing culture, change one variable, give it a name that signals what differs (`sandbox-07-escape-hatch` vs `sandbox-07b-escape-hatch-disabled`).

When in doubt about a field, check `lib/petri_dish/config.rb` in the gem (it's the schema source of truth) or look at how three existing cultures use that field.
