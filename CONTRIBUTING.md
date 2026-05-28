# Contributing to petri-dish

Thanks for considering a contribution.

## Adding an example culture

Each culture lives under `examples/<name>/` and contains:

- `config.yml`: environment, plugins, settings, runtime config, prompt mode.
- `prompt.md`: what Claude should do.

See existing examples for the shape, and read [`docs/authoring-cultures.md`](docs/authoring-cultures.md) for the conventions behind those shapes (prompt anatomy, baseline cells, preamble selection, multi-run discipline, gotchas). Culture names follow `category-NN[variant]-short-description`, e.g. `sandbox-07b-escape-hatch-disabled`.

For multi-part cultures sharing a prompt, symlink the shared prompt:

```
examples/sandbox-07b-escape-hatch-disabled/prompt.md -> ../sandbox-07-escape-hatch/prompt.md
```

## Running an example locally

```
petri-dish setup --cultures-dir examples sandbox-01-baseline
petri-dish run --cultures-dir examples sandbox-01-baseline
petri-dish results --cultures-dir examples sandbox-01-baseline
```

## Code style

- `frozen_string_literal: true` at the top of every Ruby file.
- No em-dashes in user-facing strings (use parens, colons, or split sentences).
- Keep modules small and focused.

## Submitting changes

Open a PR with a clear description of the change and which examples were verified.
