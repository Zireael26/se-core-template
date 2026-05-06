# Major upgrade watchlist

Curated list of framework-tier dependencies under deliberate version management. The `dep-major-upgrade-watch` scheduled audit reads this file every run and reports per-project drift against these targets.

**Editing rules:**

- Human-maintained. The audit reads but never writes here.
- Add a package only if "being a major behind" is a real plan-and-execute project, not a `pnpm up` away. Routine deps belong in the broad `dep-currency` view.
- When you bump a target, update `Target set` to today's date so the audit's freshness counter resets.
- Per-project overrides exist for legitimate pinning (e.g., a project intentionally on Node 20 LTS while others move to 22). Don't use them as "we'll get to it later" — that's what the drift report is for.

---

## Initialization note

All entries below were initially seeded on 2026-05-01 as part of the dep-audit
stack rollout. The first scheduled run flagged three of them (`typescript`,
`vite`, `prisma`) as already-behind-upstream on day one. Those three have been
corrected in this revision (also dated 2026-05-01). The fact that all
`Target set` dates read the same day is therefore expected; future bumps
should set the date to whenever they actually happen so the staleness signal
stays meaningful.

## Tracked packages

### next  (npm)

- **Target:** `^16` (latest stable major)
- **Target set:** 2026-05-01
- **Target reasoning:** Next 16 is the latest stable major; React 19 baseline. Migration: server-action API changes, async `cookies()` / `headers()`, partial prerendering on by default. See Next 16 upgrade guide.
- **Per-project overrides:**
  - *(none)*

### react  (npm)

- **Target:** `^19.2`
- **Target set:** 2026-05-01
- **Target reasoning:** React 19.2 is the current stable. Activation Effects + `<Activity>` API land here. Most Next 16 projects are already implicitly here via the framework's peer; this entry tracks projects that pin React directly (e.g., non-Next apps).
- **Per-project overrides:**
  - *(none)*

### react-dom  (npm)

- **Target:** `^19.2`  (must match `react`)
- **Target set:** 2026-05-01
- **Target reasoning:** Mirrors `react`; the audit will flag any project where `react` and `react-dom` are on different majors.
- **Per-project overrides:**
  - *(none)*

### typescript  (npm)

- **Target:** `^6`
- **Target set:** 2026-05-01 (revised — initial seed of `~5.7` was already a major behind; first audit caught it)
- **Target reasoning:** TS 6 is the current stable major (latest at revision: 6.0.3). Caret range so projects accept any 6.x version without the audit complaining. The 5 → 6 jump tightens checking around `unknown`-handling and dependency-tracking; check each project's third-party type packages before bumping.
- **Per-project overrides:**
  - *(none)*

### node  (engine)

- **Target:** `>=22.0.0` (any active LTS line — 22 in Maintenance LTS, 24 in Active LTS as of target-set date)
- **Target set:** 2026-05-01
- **Target reasoning:** Open-floor against the `>=22` line: projects on Node 22 (Maintenance LTS) AND projects on Node 24 (Active LTS, since Oct 2025) are both acceptable. Node 20 is end-of-life on 2026-04-30 — projects still on 20 will fail this check. Track via each project's `package.json#engines.node` AND `.nvmrc` / `.node-version` (audit reports both with `(mismatch)` flag if they disagree). Latest LTS query for upstream cross-check: `https://nodejs.org/dist/index.json` filtered to `lts != false`.
- **Per-project overrides:**
  - *(none)*

### tailwindcss  (npm)

- **Target:** `^4`
- **Target set:** 2026-05-01
- **Target reasoning:** Tailwind v4 (Oxide) is the current major; v3 → v4 is non-trivial (CSS-first config via `@theme`, Lightning CSS pipeline, plugin compat). Project Beta is already on v4.
- **Per-project overrides:**
  - *(none)*

### vite  (npm)

- **Target:** `^8`
- **Target set:** 2026-05-01 (revised — initial seed of `^7` was already a major behind; first audit caught it)
- **Target reasoning:** Vite 8 is the current major (latest at revision: 8.0.10). For non-Next projects using Vite. Skip if the project doesn't use Vite (audit reports `not-applicable`). 7 → 8 dropped Node 18 support and updated Rollup; verify `engines.node` is on 22 LTS first.
- **Per-project overrides:**
  - *(none)*

### unity  (engine — Project Zeta only)

- **Target:** `6000.4 LTS` (Unity 6 LTS line)
- **Target set:** 2026-05-01 (revised — initial seed of `2022.3 LTS` was already two LTS lines behind; Project Zeta itself is on `6000.4.4f1` at revision time)
- **Target reasoning:** Unity 6 LTS (6000.x) is the current LTS line and Project Zeta is already on it. Tilde-style range against the major-LTS so patch bumps within `6000.4.x` don't trigger the audit; jumping to `6000.5 LTS` or beyond would. Sourced from `<project-root>/ProjectSettings/ProjectVersion.txt` `m_EditorVersion` field. Project Zeta's project root is nested at `Project ZetaApp/`; the audit auto-probes the conventional sub-paths. No programmatic upstream lookup for Unity exists; bumps here happen via human review.
- **Per-project overrides:**
  - *(none)*

---

## Format reference (for future entries)

```
### <package>  (<ecosystem>)

- **Target:** <semver range or version pin>
- **Target set:** YYYY-MM-DD
- **Target reasoning:** <one or two sentences. why this target, what's gating, where the migration guide lives>
- **Per-project overrides:**
  - <project-name>: <override target> — <reason>
  - <project-name>: <override target> — <reason>
```

Ecosystem values the audit understands: `npm`, `pypi`, `cargo`, `go`, `nuget`, `engine` (catch-all for runtimes/IDEs that don't have a package manager).
