# AGENT_SETUP.md — paste-into-Claude prompt

> **For the human:** clone this repo, then paste **everything below the `--- BEGIN PROMPT ---` line** into a Claude conversation that has filesystem and shell tools (Claude Code, Cowork, or any Claude that can `Read`/`Write`/`Bash`). The agent will interview you, replace placeholders across the repo, install the inheritance symlink in your projects, seed husky hooks, and update the registry.
>
> Make sure your Claude session has the cloned repo available — open Claude Code from inside it (`cd ~/projects/se-core && claude`), or in Cowork connect the cloned folder.

---

## --- BEGIN PROMPT ---

You are bootstrapping **SE Core** — a multi-project engineering-process control plane — on this machine. The repo we're in is a redacted template; your job is to customize it for the user, then optionally onboard their first project. Work carefully and verify each step.

### Context you should establish first

Before touching anything, read these files in order so you understand the system:

1. `README.md` — high-level overview and the placeholder list.
2. `core-rules/CLAUDE.md` — the parent rules every project will inherit (~5 KB).
3. `core-rules/inheritance.md` — the load-bearing symlink mechanism (this is critical; it's how rules reach `claude -p` headless sessions).
4. `core-rules/hooks.md` — the three-tier hook architecture.
5. `engineering-process.md` §§1-5 only at this stage — the narrative manual; sections 1-5 cover philosophy, control plane, and project regime. Skip the rest until later.

After reading, confirm to the user in one short paragraph what SE Core is and what you're about to do, then continue.

### Step 1 — Interview the user for placeholder values

Use whatever clarification mechanism your tooling provides (multi-choice question tool if available, or just ask in chat). You need five values:

- `__SE_CORE_PATH__` — absolute path to this cloned repo. **Auto-detect** from your current working directory using `pwd` (run it with `bash`); confirm with the user before using it.
- `__PROJECTS_ROOT__` — absolute path to the parent dir holding the user's personal projects. Examples: `/Users/<user>/projects/personal`, `/home/<user>/code`. Default the suggestion to a sibling of `__SE_CORE_PATH__` named `personal`. Confirm with the user.
- `__MAINTAINER_NAME__` — the user's display name (used in `engineering-process.md`).
- `__GITHUB_USER__` — the user's GitHub username (referenced in audit examples and registry comments).
- `__USER_HOME__` — the user's home directory. Auto-detect via `echo $HOME`; confirm.

Echo the five values back to the user in a clear table and ask "Should I proceed with these?" Wait for explicit yes.

### Step 2 — Replace placeholders across the repo

Run this from the repo root. The exclusion list keeps four files untouched: `LICENSE`, `README.md`, `SETUP.md`, and `AGENT_SETUP.md` itself — they reference placeholders by literal name as documentation.

```bash
SE_CORE_PATH="<from-step-1>"
PROJECTS_ROOT="<from-step-1>"
MAINTAINER_NAME="<from-step-1>"
GITHUB_USER="<from-step-1>"
USER_HOME="<from-step-1>"

# Detect sed flavor (BSD on macOS vs GNU on Linux).
if sed --version >/dev/null 2>&1; then
  SED_INPLACE=(-i)        # GNU
else
  SED_INPLACE=(-i '')     # BSD/macOS
fi

find . -type f \
  ! -path './.git/*' \
  ! -name LICENSE ! -name README.md ! -name SETUP.md ! -name AGENT_SETUP.md \
  -exec sed "${SED_INPLACE[@]}" \
    -e "s|__SE_CORE_PATH__|$SE_CORE_PATH|g" \
    -e "s|__PROJECTS_ROOT__|$PROJECTS_ROOT|g" \
    -e "s|__MAINTAINER_NAME__|$MAINTAINER_NAME|g" \
    -e "s|__GITHUB_USER__|$GITHUB_USER|g" \
    -e "s|__USER_HOME__|$USER_HOME|g" \
    {} +
```

**Verification:** grep for any leftover placeholder. Output should be empty.

```bash
grep -rn "__SE_CORE_PATH__\|__PROJECTS_ROOT__\|__MAINTAINER_NAME__\|__GITHUB_USER__\|__USER_HOME__" . \
  --exclude-dir=.git --exclude=LICENSE --exclude=README.md --exclude=SETUP.md --exclude=AGENT_SETUP.md
```

If anything matches, fix it before continuing. Report findings to the user.

### Step 3 — Smoke-test the canonical files

Sanity checks the user can trust:

```bash
# Hooks are executable
ls -la core-rules/hooks/*.sh core-rules/husky/* scripts/onboard-project.sh

# Symlink target exists (used in step 4)
test -f "$SE_CORE_PATH/core-rules/CLAUDE.md" && echo OK
```

If any are not executable:

```bash
chmod +x core-rules/hooks/*.sh core-rules/husky/* scripts/onboard-project.sh
```

### Step 4 — Commit the customization

```bash
git add -A
git status
git commit -m "chore: bootstrap SE Core for $USER"
```

Show the user the commit. Don't push yet — wait until after step 5 in case the user wants to change the remote.

### Step 5 — (Optional) Repoint git remote

The cloned remote currently points at the template repo on GitHub. If the user wants their own copy, ask whether they want to:

- (a) **Fork on GitHub then re-point.** Best if they want a public fork with provenance back to the template.
- (b) **Create a new private repo and re-point.** Best for a personal control plane.
- (c) **Leave the remote alone.** Useful if they're just trying SE Core out and may delete it.

For (b), instruct the user to create the repo themselves on GitHub (creating accounts/repos requires their input — don't do it for them). Once they've created it:

```bash
git remote set-url origin git@github.com:<USER>/se-core.git
git push -u origin main
```

For (a), ask the user to fork via GitHub UI, then guide them through `git remote set-url`.

### Step 6 — (Optional) Onboard their first project

Ask the user: "Do you have an existing personal project you'd like to register under SE Core right now? (Y/N)"

If yes:

1. Ask for the absolute path. Verify it's a directory and a git repo.

2. Run the onboarding script (it auto-detects SE Core's location):

   ```bash
   ./scripts/onboard-project.sh /absolute/path/to/their/project
   ```

3. Follow the script's "Next steps" output. Specifically:
   - Add the `@`-import line at the top of `<project>/CLAUDE.md`. Read the file first; if the user has no `CLAUDE.md`, create a minimal one with just the import line and a one-line "project-specific rules go below" header. Don't invent project-specific rules — that's for them.
   - In the project dir, run `git status` and present the new files (`.claude/rules/se-core.md`, `gotchas.md`, `context-log.md`, and the `.husky/*` files if Node) for the user's review.
   - Suggest the commit message: `chore: onboard to SE Core`.
   - Remind the user to run `pnpm install` (or `bun install` / `npm install`) so husky activates `core.hooksPath`.

4. Back in the SE Core repo, append a row to `registry.md`:

   ```markdown
   | <project-name> | `<absolute-path>` | <class — see existing rows for examples> | Onboarded YYYY-MM-DD. |
   ```

   Commit: `chore: register <project-name>`.

If the user has no project to onboard yet, that's fine — SE Core sits idle until they do. Tell them where the onboarding script is for later.

### Step 7 — Final report

Tell the user, in this order:

1. **What you did.** A short paragraph: which placeholders were swapped, whether you committed, whether the remote was repointed, whether a project was onboarded.
2. **What's still on them.** Three concrete things: (a) push the customization commit if they want it on a remote, (b) read `engineering-process.md` cover-to-cover for the manual, (c) if they registered a project, run `pnpm install` (or equivalent) inside it so husky activates.
3. **Where to look next.** Point them at `core-rules/CLAUDE.md` (the rules), `scheduled-tasks/README.md` (the audit fleet — optional to wire up), and `examples/audits/` (sample reports).

Don't write a tutorial — they have one in `engineering-process.md`. Just hand off cleanly.

### Discipline you should follow throughout

- **Read before editing.** Before any `sed` / `Edit` / `Write`, read the target file. The `core-rules/CLAUDE.md` rules you're installing apply to you too.
- **Verify after editing.** After the `sed` pass in step 2, grep for leftovers. After the symlink creation in step 6, `ls -la <project>/.claude/rules/se-core.md` and confirm it resolves.
- **Don't push without explicit permission.** Step 4 is a local commit; step 5 asks before pushing.
- **Don't create accounts or repos for the user.** If a step needs a new GitHub repo, ask the user to create it and paste the URL.
- **Don't invent project-specific rules.** When seeding a new project's `CLAUDE.md`, keep it minimal — just the `@`-import. The user will fill in their own.
- **One thing at a time.** Wait for "yes" before each major step. The user is in the loop.

## --- END PROMPT ---
