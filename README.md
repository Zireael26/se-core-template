# SE Core Template

A starter for **Software Engineering Core** — a parent/child engineering-process regime for solo developers running multiple Claude Code projects. SE Core gives you:

- **Cross-project rules in one place** (`core-rules/CLAUDE.md`) that every registered project inherits — load-bearing in both interactive and headless `claude -p` mode.
- **A hook stack** that enforces the rules mechanically: block destructive commands, lint on every edit, typecheck + lint + test on every wrap-up, code review on edit-heavy turns, screenshot-verify UI changes, and a husky tier that blocks direct pushes to `main`.
- **A scheduled audit fleet** (10 Tier-1 audits) that scans every registered project weekly/monthly for hook drift, dependency posture, test health, bypass attempts, and process compliance — writing reports to `audits/`.
- **A Rule-of-Three discipline** for adding new parent rules: candidates wait in `core-rules/deferred.md` until three independent projects adopt them.

Read `engineering-process.md` for the full narrative manual once you're set up.

## Quick start

You are about to clone this template and customize it for your own machine.

> **Two ways to set up.** Pick one.
>
> **(A) Agent-driven (recommended).** Open this repo in Claude Code (or paste the contents of [`AGENT_SETUP.md`](AGENT_SETUP.md) into a Claude conversation that has filesystem tools). The agent will interview you, fill in the placeholders, install the inheritance symlink across your projects, and seed husky hooks. ~10 minutes, no manual sed.
>
> **(B) Manual.** Follow [`SETUP.md`](SETUP.md) step by step. ~30 minutes, more sed.

## Repo layout

```
.
├── README.md                  ← you are here
├── SETUP.md                   ← human-facing setup walkthrough
├── AGENT_SETUP.md             ← paste-into-Claude prompt that does setup for you
├── LICENSE                    ← MIT
│
├── core-rules/                ← THE PARENT LAYER — what every project inherits
│   ├── CLAUDE.md              ← terse rules Claude loads at session start
│   ├── hooks.md               ← spec for the 9 canonical hooks (3 tiers)
│   ├── hooks/                 ← canonical shell implementations of those hooks
│   ├── husky/                 ← canonical pre-commit / commit-msg / pre-push
│   ├── templates/             ← per-project file templates (gotchas.md, context-log.md)
│   ├── inheritance.md         ← how `.claude/rules/` symlink + `@`-import work
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
│   └── onboard-project.sh     ← one-shot: register a new project under SE Core
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
| `__SE_CORE_PATH__`     | Absolute path where you cloned this repo                       | `/Users/jane/projects/se-core`     |
| `__PROJECTS_ROOT__`    | Absolute path to the parent dir holding your projects          | `/Users/jane/projects/personal`    |
| `__MAINTAINER_NAME__`  | Your name (used in `engineering-process.md`)                   | `Jane Doe`                         |
| `__GITHUB_USER__`      | Your GitHub username (referenced in audit-flow examples)       | `janedoe`                          |
| `__USER_HOME__`        | Your home directory (rare — only in a couple of legacy refs)   | `/Users/jane`                      |

`AGENT_SETUP.md` walks an LLM through asking you for these values and substituting them.

## Requirements

- **macOS or Linux** with `bash`, `git`, and `jq` on `PATH`. Hooks degrade gracefully if jq is missing.
- **Node.js** if any of your projects use husky-managed git hooks. (For Unity / Rust / Go / Python-only projects, see `core-rules/inheritance.md` "Native git hooks".)
- **Claude Code** for the inheritance symlink + scheduled-task plumbing to be useful end-to-end. Most of the rules apply more broadly, but the symlink mechanism specifically serves Claude Code session loading.

## License

MIT. See `LICENSE` and `docs/PROVENANCE.md` for upstream attribution.
