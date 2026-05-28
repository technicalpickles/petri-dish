# petri-dish Claude Code plugin

Teaches Claude Code how to author petri-dish cultures: schema, prompt anatomy, baseline cells, multi-run discipline, and the brittle bits to watch for.

Installed through the [`pickled-claude-plugins`](https://github.com/technicalpickles/pickled-claude-plugins) marketplace, which sparse-clones this directory via a `git-subdir` source.

## Install

The `petri-dish` gem needs to be on your PATH first. See the [top-level README](../README.md#install).

Then add the marketplace (if you haven't already) and install the plugin:

```bash
claude plugin marketplace add technicalpickles/pickled-claude-plugins
claude plugin install petri-dish@pickled-claude-plugins
```

Restart Claude Code so it picks up the skill.

## What you get

Once installed, Claude reaches for the skill when you ask things like:

- "Write a petri-dish culture that probes whether Claude reaches for the LSP when asked to find a class definition."
- "Add an A/B variant of `sandbox-01-baseline` that turns the sandbox off."
- "What's a sensible baseline cell for investigating permission-prompt behavior?"
- "Why is my prompt producing prose instead of parseable results?"

The skill carries the schema, the prompt-shape conventions, the preamble selection table, and the cell-discipline rules inline. For the full reference (and the why behind each rule), it links to [`skills/petri-dish/references/authoring-cultures.md`](skills/petri-dish/references/authoring-cultures.md), which travels with the plugin.

## When it doesn't fire

If Claude is writing a culture without surfacing the conventions (no preamble selection, no signal-file instruction, batched questions), say "use the petri-dish skill" explicitly. If it consistently misses on phrasings it should catch, that's worth an issue. The skill description can always use a tune.

## Contents

- `.claude-plugin/plugin.json`: manifest
- `skills/petri-dish/SKILL.md`: the skill that teaches Claude when and how to author cultures

## Updating the skill

Edit `skills/petri-dish/SKILL.md` in place and open a PR against this repo. The marketplace tracks `ref: "main"` today, so merged changes flow out to installs on the next update.
