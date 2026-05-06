# Reference — Stack profiles

The canonical six gates (PR hygiene, secrets, bypass, tests, docs, stack profile) apply to every project. Stack-profile validators handle stack-specific concerns the canonical six don't cover.

Profiles are project-declared. Setting `PROCESS_GATE_STACK_PROFILE` in `local.config.sh` makes the verdict's "Stack profile" row meaningful.

## Profiles in current use

### `web-next` — Next.js / Vercel projects

Typical validators contributors add at the project level:

- `check-tokens.sh` — design-token fidelity (no raw hex outside the token file, no off-scale spacing).
- `check-a11y.sh` — `pnpm test:a11y` against the running preview (axe-core).
- `check-input-font-size.sh` — iOS-zoom guard (input fields ≥ 16px to prevent zoom on focus).
- `check-phrases.sh` — forbidden-phrase list (brand voice).

These are project-specific implementations; the canonical layer doesn't ship them. Keep worked examples in project-local docs until a validator is promoted.

### `monorepo-pnpm` — pnpm-workspace monorepos

Common validators:

- `check-module-boundary.sh` — package import-boundary enforcement (for example, one workspace package may not import from another forbidden layer).
- `check-package-graph.sh` — circular-dep detection.
- `check-scope-allowlist.sh` — Conventional-Commit scope must match a workspace package name.

Keep worked examples project-local until a validator is promoted.

### `unity` — Unity / native game projects

Common validators:

- `check-meta-files.sh` — every asset has a paired `.meta` file.
- `check-asset-bundle.sh` — `.unity` and `.prefab` files don't have merge-conflict markers.
- `check-no-binary-bloat.sh` — diff size sanity for binary assets.

The canonical Unity profile defers to Rule of Three until three independent game/native projects need the same validator shape.

### `native-other` — Rust / Go / Python / etc.

Project supplies its own validators. No canonical defaults.

### `n-a` — explicit opt-out

Used when stack-specific gates legitimately don't apply. The verdict row renders as `➖ n/a`. Rare; document the reason in the project's `gotchas.md` and the registry-row notes.

## Adding a stack-profile validator

In the project's `process-gate-local/local.config.sh`:

```bash
PROCESS_GATE_STACK_PROFILE="web-next"
PROCESS_GATE_STACK_VALIDATORS=(
  "scripts/check-tokens.sh"
  "scripts/check-a11y.sh"
  "scripts/check-input-font-size.sh"
  "scripts/check-phrases.sh"
)
```

Relative paths are resolved from the harness-local extension directory first:

- Claude Code: `<project>/.claude/skills/process-gate-local/`
- Codex: `<project>/.agents/skills/process-gate-local/`

If a validator is not found there, `run-all.sh` falls back to the canonical
skill symlink (`<project>/.claude/skills/process-gate/` or
`<project>/.agents/skills/process-gate/`) so promoted canonical validators can
still be referenced by relative path.

Each validator script must:

- Exit `0` for pass, `1` for fail, `2` for warn.
- Print findings to stdout in the format `<file>:<line>: <message>` so they merge into the verdict's Findings section.
- Honor `--range=<gitspec>` if relevant.

## Promoting a profile to canonical

When three independent projects adopt a close variant of the same validator, promote per `engineering-process.md` §14 (Rule of Three):

1. Move the validator into `$SE_CORE_ROOT/core-rules/skills/process-gate/scripts/`.
2. Add a corresponding reference under `references/`.
3. Update this `stack-profiles.md` to reflect the new canonical profile.
4. Run the extended `parent-hook-drift` audit to verify byte-identity across projects.

Profiles waiting for a third witness queue in `core-rules/deferred.md`.

## Unity carve-out

Unity/native game projects can declare `PROCESS_GATE_STACK_PROFILE="unity"`. Stack-specific validators are project-local until the Rule of Three promotes them. The canonical six gates still apply.

Document the carve-out in the project's `registry.md` row. The extended `parent-hook-drift` audit treats `PROCESS_GATE_STACK_PROFILE="unity"` with no canonical scripts as expected, not drift.
