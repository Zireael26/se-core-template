# Provenance & attribution

This template is a redacted snapshot of an active SE Core deployment, packaged for re-use.

## Lineage

```
github.com/iamfakeguru/claude-md   (MIT)
        │
        │   Seed: block-destructive, post-edit-verify, stop-verify, truncation-check
        │   hooks. Two-tier hook architecture concept.
        ▼
SE Core (live)                     (private source repository)
        │
        │   Extensions: three-tier hook architecture (fast-local + heavy-gated + git-boundary),
        │   stop-verify TodoWrite guard, code-review-subagent + ui-verify hook skeletons,
        │   session-context / save-context-log / post-compact-context hooks, scheduled
        │   audit stack (cross-project process audit, dep-currency, dep-vulnerabilities,
        │   dep-major-upgrade-watch, bypass-tripwire, parent-hook-drift, gotchas-rollup,
        │   audit-report-rollup, registry-blacklist-health, test-health), inheritance
        │   mechanism (`.claude/rules/` symlink as primary, `@`-import as fallback),
        │   Rule-of-Three discipline with `core-rules/deferred.md`.
        ▼
SE Core Template                   (this repo)
        │
        │   Same structure, redacted: project names replaced with `project-a..f`,
        │   absolute paths replaced with `__SE_CORE_PATH__` / `__PROJECTS_ROOT__`
        │   placeholders, real audit history reduced to four representative examples
        │   under `examples/audits/`.
        ▼
Your fork                          (you fill in placeholders during AGENT_SETUP.md)
```

## What's verbatim from upstream (`iamfakeguru/claude-md`)

The following hook scripts under `core-rules/hooks/` carry "upstream" or "upstream, extended" markers in their headers — those parts trace to iamfakeguru/claude-md (MIT):

- `block-destructive.sh` (extended: `DELETE FROM` w/o `WHERE`, `**/secrets/**` glob, exfil patterns)
- `post-edit-verify.sh` (extended: Go and Rust support)
- `stop-verify.sh` (extended: TodoWrite guard, Go support, last-30-lines slicing for tests)
- `truncation-check.sh` (extended: explicit 50K-char threshold per spec)

## What's net-new in this template (vs. upstream)

- Three-tier hook architecture (`core-rules/hooks.md`)
- `code-review-subagent.sh` + `ui-verify.sh` hook skeletons (no upstream equivalents)
- Inheritance mechanism: `.claude/rules/se-core.md` symlink as load-bearing primary, `@`-import as interactive fallback (`core-rules/inheritance.md`)
- The whole `scheduled-tasks/` stack (10 Tier-1 tasks + 2 Tier-2 drafts)
- Rule of Three / `core-rules/deferred.md` discipline
- `engineering-process.md` narrative manual

## License

MIT, same as the upstream. See `LICENSE`.
