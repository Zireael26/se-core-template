# Gotchas rollup — 2026-05-01

First monthly rollup. No prior `gotchas-rollup` audit on disk.

## Summary

- Projects scanned: **6** (project-a, project-b, project-c, project-d, project-e, project-f)
- Projects with empty `gotchas.md`: **2** (project-a, project-c)
- Gotchas collected: **10** (project-b 5, project-e 3, project-d 1, project-f 1)
- Clusters formed: **9** (1 cross-project n=2; 8 singletons)
- Promote candidates (n≥3): **0**
- `deferred.md` candidates (n=2): **1**
- Watch items (n=1): **8**
- `deferred.md` graduations recommended: **0**
- `deferred.md` stale removals recommended: **0**

## Promote candidates (n≥3) — draft rules

None this month.

## `deferred.md` updates

### Additions (n=2, not yet in `deferred.md`)

#### "Code change requires a paired non-code-asset update in the same commit"

- **Evidence:**
  - **project-e** (2026-04-25) — renamed `theme` → `themePresetKey` in `apps/api-gateway/src/lib/openapi.ts`; the checked-in `docs/api/02-openapi.yaml` was not regenerated. `bun run typecheck` passed; the byte-comparison test "checked-in YAML matches the shared public spec builder" failed only when the Stop hook ran the suite.
  - **project-f** (2026-04-25) — `BootstrapController` and `PerformanceMonitor` MonoBehaviours were authored under `Assets/Scripts/`; the scene file (`Assets/Scenes/SampleScene.unity`) was never updated to attach them to a `Bootstrap` GameObject. Code compiled and the project ran, but the FPS HUD was silently absent and `[Perf]` `Debug.Log` was silent until a manual Editor follow-up.

- **Proposed deferred entry (lift when a third project confirms):**

  > **Code-asset pairing rule.** When a code change has a non-code companion artifact (a checked-in generated file, a scene/prefab reference, a fixture, a snapshot, a binding manifest), update the companion in the **same commit**. Static checks (typecheck, build, lint) cannot detect drift between code and these companions; the failure surfaces only via an integrity test or at runtime.

- **Why defer rather than promote now:** the underlying lesson is the same — *static checks are blind to code/asset drift* — but the mechanisms differ enough (a regenerated YAML vs. a Unity scene wire-up) that the right shape of the rule isn't yet obvious. A third instance from a different domain would tell us whether to phrase this as "regenerate generated artifacts" (narrow, file-scoped) or as a broader "code-asset pairing" invariant with per-project enforcement hooks.

- **What would graduate it:** a third project independently reports a bug whose root cause is a code change landing without its paired non-code artifact (e.g., GraphQL schema dump out of sync, Storybook snapshot not regenerated, locale file drift, IaC plan not re-applied).

### Confirmations (n=2, already in `deferred.md` — evidence added)

None — none of the existing `deferred.md` entries had supporting evidence appear in any project's `gotchas.md` this period.

Note on the **ADR numbered-sequential doc folder** entry: `registry.md` documents that project-f adopted the ADR pattern ("ADR pattern adopted (n=2 with Project-B)"), which would put it at n=2 by the registry's count. However, this signal comes from the registry, not from `gotchas.md` evidence, so per this rollup's input scope it does not change the deferred entry's status. Calling it out in case the user wants to reconcile sources.

### Graduations (now n≥3, recommend moving to `CLAUDE.md`)

None.

### Stale removals (last data point >6 months ago)

None. Every entry in `deferred.md` is recent (Project-A/Project-B seeded April 2026 onboarding; oldest data point ~2026-04-24).

## Watch items (n=1)

Project-singleton entries — log only, no action this month.

- **project-b — Custom-element JSX intrinsics in React 19 + TS 6 strict.** `namespace JSX` augmentation in `.tsx` triggers `@typescript-eslint/no-namespace`; lift the declaration into a `.d.ts` ambient module file.
- **project-b — `vi.unstubAllEnvs()` only rolls back stubs created during the test.** Vars set in `.env.local` before the suite leak through. Open suites with an explicit `vi.stubEnv('VAR_NAME', '')` so teardown has something to undo.
- **project-b — Shadow-DOM launcher buttons unreliable with bounding-box clicks.** Center-click hits the host shell, not the button inside the shadow root; wait on `role="dialog"` / `[data-state="open"]` / `[aria-expanded="true"]` before asserting open-state behavior.
- **project-b — CSP `script-src 'unsafe-inline'` is a Next 16 transitional crutch.** RSC injects inline `<script>` tags that can't be nonce-attributed without custom server setup; HMR runs clean without `'unsafe-eval'` on Next 16.2 + Turbopack. Replace with nonces once the infrastructure exists.
- **project-b — `headers()` in `next.config.ts` must be inside the inner config object.** When `withSentryConfig` / `withBundleAnalyzer` wrap the config, `headers()` placed on the outer return is invisible to Next.js. Define inside the base config before wrappers run.
- **project-d — `c2d-standard-4` in `asia-south1` needs explicit quota grant; new projects blocked by `NOT_ENOUGH_USAGE_HISTORY`.** Global `effectiveLimit=-1` lies; the per-region bucket has no `effectiveLimit` field and falls through to 0. Self-serve increase is blocked until the project has 30–60 days of usage history. Query the per-region bucket explicitly before committing to a machine series in a region.
- **project-e — Submodule SHA bump on parent without first pushing the submodule branch breaks every parent CI workflow that does `git submodule update`.** Always `git -C apps/<service> push origin <branch>` BEFORE `git push origin <parent-branch>` for any parent commit that bumps a submodule pointer. Pre-push hook does not currently enforce this. (Repeats once → escalate.)
- **project-e — `c.get('tenant')` context variable never set; routes are dead code at runtime.** No middleware in the codebase populates `tenant`; routes return 400 on every call. A type-only fix (declaring `tenant` in `AppEnv.Variables`) makes typecheck happy but masks the runtime bug. Real fix is middleware that populates `tenant` from the `tenantId` claim, or refactor call sites to fetch via repository.

## What to do

1. **Review the proposed `deferred.md` addition** ("Code-asset pairing rule"). If the framing fits, add it to `core-rules/deferred.md` with Project-B/project-f citations and the graduation criterion above. If you'd rather wait for a third confirming instance before parking it formally, that's also defensible — the n=2 pair lands in the same week from two very different stacks (TypeScript backend and Unity), which is a stronger pattern signal than a typical n=2 but still inside the danger zone the `deferred.md` preamble warns about.

2. **Reconcile the ADR signal.** `registry.md` records project-f + Project-B as n=2 on the ADR pattern, but no `gotchas.md` entry confirms that. If you want the rollup to use that signal in the future, capture the adoption in each project's `gotchas.md` (or in a separate `adoptions.md`); right now it lives only in the registry's freeform notes column and is invisible to this audit.

3. **Tooling-gap check:**
   - The project-e OpenAPI / project-f scene-wiring cluster ("non-code companion artifact") is a candidate for a precommit hook in project-e specifically: regenerate `docs/api/02-openapi.yaml` whenever `apps/api-gateway/src/lib/openapi.ts` changes, and fail the commit if the diff is non-empty. project-f's scene-wiring case is harder to automate (Unity scene files are diffable but not amenable to a shell hook); could file a follow-up to write an Editor build-script that creates the `Bootstrap` GameObject programmatically — the project-f `gotchas.md` already flags this as a watch-for-recurrence.
   - The project-e submodule-push-order entry explicitly notes the pre-push hook does not enforce submodule push ordering. Worth a hook addition in project-e to fail any parent push that includes a submodule-pointer bump whose target SHA is not yet on the submodule's remote. Even if it stays a project-e-local hook, the rule is unambiguous.
   - The project-e api-gateway "typecheck alone is not enough; need `bun test`" entry implies a per-lane verification policy — typecheck-only is the wrong default for any package with byte-comparison or schema-integrity tests. Could be lifted into a project-e-local `core-rules/inheritance.md` companion; not a parent-rule candidate yet.

## Notes on coverage

- **project-a** (`__PROJECTS_ROOT__/project-a/gotchas.md`) is empty as of this rollup. Given Project-A is the largest active project and the seed for many `deferred.md` entries, an empty gotchas log is itself worth a sanity check — either lessons aren't being captured at the project level, or activity in this period genuinely produced none. No action taken; just flagging.
- **project-c** (`__PROJECTS_ROOT__/project-c/gotchas.md`) is empty, consistent with `registry.md` noting "Lower activity; include when next touched."
- All six target projects had a `gotchas.md` present in the expected location; no parse errors; no projects skipped for malformed input.
