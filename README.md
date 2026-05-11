# SE Core Template

A starter for **Software Engineering Core** — a parent/child engineering-process regime for developers running multiple Claude Code and Codex projects. SE Core gives you:

- **Cross-project rules in one place** (`core-rules/CLAUDE.md`) that every registered project inherits through Claude Code (`CLAUDE.md` / `.claude/`) and Codex (`AGENTS.md` / `.agents/`) entrypoints.
- **Harness-specific hook stacks**: Claude Code uses `.claude/hooks/`; Codex uses `.codex/hooks.json` and `.codex/hooks/`; both share the same policy intent.
- **A process-gate skill** exposed through both `.claude/skills/process-gate` and `.agents/skills/process-gate` when Codex is enabled.
- **A scheduled audit fleet** (10 Tier-1 audits) that scans every registered project weekly/monthly for hook drift, dependency posture, test health, bypass attempts, and process compliance — writing reports to `audits/`.
- **A Rule-of-Three discipline** for adding new parent rules: candidates wait in `core-rules/deferred.md` until three independent projects adopt them.

Read `engineering-process.md` for the full narrative manual once you're set up.

## Quick start

You are about to clone this template and customize it for your own machine.

> **Two ways to set up.** Pick one.
>
> **(A) Agent-driven (recommended).** Open this repo in Claude Code or Codex, or paste the contents of [`AGENT_SETUP.md`](AGENT_SETUP.md) into an agent conversation that has filesystem tools. The agent will interview you, fill in the placeholders, ask whether to enable Codex parity, install inheritance symlinks, and seed hooks. ~10 minutes, no manual sed.
>
> **(B) Manual.** Follow [`SETUP.md`](SETUP.md) step by step. ~30 minutes, more sed.

After SE Core is bootstrapped, **onboard projects** with the agent-driven flow in [`AGENT_ONBOARD_PROJECT.md`](AGENT_ONBOARD_PROJECT.md) — paste it into an agent open in your customized `se-core/` and it interviews you, runs `scripts/onboard-project.sh`, wires the project's `CLAUDE.md`, updates `registry.md`, and commits. Works for new projects, fresh clones of registered projects, and drift repair. Equivalent manual path: [`engineering-process.md` §10](engineering-process.md).

## Repo layout

```
.
├── README.md                  ← you are here
├── SETUP.md                   ← human-facing setup walkthrough
├── AGENT_SETUP.md             ← paste-into-agent prompt that does setup for you
├── LICENSE                    ← MIT
│
├── core-rules/                ← THE PARENT LAYER — what every project inherits
│   ├── CLAUDE.md              ← terse parent rules
│   ├── AGENTS.md              ← symlink → CLAUDE.md for Codex parity
│   ├── hooks.md               ← spec for the 9 canonical hooks (3 tiers)
│   ├── hooks/                 ← canonical Claude Code hook implementations
│   ├── codex/                 ← canonical Codex hooks.json + hook scripts
│   ├── husky/                 ← canonical pre-commit / commit-msg / pre-push
│   ├── templates/             ← per-project file templates (gotchas.md, context-log.md)
│   ├── inheritance.md         ← how Claude and Codex inheritance work
│   └── deferred.md            ← rules waiting for their 3rd project (Rule of Three)
│
├── registry.md                ← list of projects under SE Core management (you fill in)
├── blacklist.md               ← projects to skip (yours to maintain)
│
├── engineering-process.md     ← THE MANUAL — narrative source of truth
│
├── scheduled-tasks/           ← 10 audits + 2 drafts; each is a prompt + targets
│   ├── README.md
│   ├── cross-project-process-audit/
│   ├── dep-currency/
│   └── … (8 more)
│
├── scripts/
│   ├── onboard-project.sh     ← one-shot: register a new project under SE Core
│   ├── sync-hooks.sh          ← sync Claude Code hooks
│   └── sync-codex-hooks.sh    ← sync Codex hooks when enabled
│
├── audits/                    ← generated audit reports land here (initially empty)
├── examples/audits/           ← redacted sample reports — what audits look like
└── docs/
    ├── PROVENANCE.md          ← attribution & lineage
    └── upstream-recon.md      ← original LIFT/LEAVE/DEFER methodology document
```

## What you customize

Three placeholders appear throughout the repo. Setup replaces them in-place:

| Placeholder            | What it becomes                                                | Example                            |
|------------------------|----------------------------------------------------------------|------------------------------------|
| `__SE_CORE_PATH__`     | Absolute path where you cloned this repo                       | `/path/to/se-core`                 |
| `__PROJECTS_ROOT__`    | Absolute path to the parent dir holding your projects          | `/path/to/projects`                |
| `__MAINTAINER_NAME__`  | Your name (used in `engineering-process.md`)                   | `Jane Doe`                         |
| `__GITHUB_USER__`      | Your GitHub username (referenced in audit-flow examples)       | `janedoe`                          |
| `__USER_HOME__`        | Your home directory (rare — only in a couple of legacy refs)   | `/home/jane`                       |

`AGENT_SETUP.md` walks an LLM through asking you for these values, choosing harnesses, and substituting them.

## Requirements

- **macOS or Linux** with `bash`, `git`, and `jq` on `PATH`. Hooks degrade gracefully if jq is missing.
- **Node.js** if any of your projects use husky-managed git hooks. (For Unity / Rust / Go / Python-only projects, see `core-rules/inheritance.md` "Native git hooks".)
- **Claude Code and/or Codex**. The default config enables both harnesses. Claude Code uses `.claude/`; Codex uses `AGENTS.md`, `.agents/`, `.codex/hooks.json`, and `.codex/hooks/`. You can remove either harness from `se-core.config.json` if you intentionally do not use it.
- **Codex hooks opt-in** requires Codex CLI with hooks support and `[features] codex_hooks = true` in `$CODEX_HOME/config.toml`.

## License

MIT. See `LICENSE` and `docs/PROVENANCE.md` for upstream attribution.
