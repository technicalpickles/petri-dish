# Contributing to Petri

Thanks for considering a contribution.

## Adding an example test

Each test lives under `examples/<name>/` and contains:

- `config.yml`: environment, plugins, settings, runtime config, prompt mode.
- `prompt.md`: what Claude should do.

See existing examples for the shape. Test names follow `category-NN[variant]-short-description`, e.g. `sandbox-07b-escape-hatch-disabled`.

For multi-part tests sharing a prompt, symlink the shared prompt:

```
examples/sandbox-07b-escape-hatch-disabled/prompt.md -> ../sandbox-07-escape-hatch/prompt.md
```

## Running an example locally

```
petri setup --tests-dir examples sandbox-01-baseline
petri run --tests-dir examples sandbox-01-baseline
petri results --tests-dir examples sandbox-01-baseline
```

## Code style

- `frozen_string_literal: true` at the top of every Ruby file.
- No em-dashes in user-facing strings (use parens, colons, or split sentences).
- Keep modules small and focused.

## Submitting changes

Open a PR with a clear description of the change and which examples were verified.
