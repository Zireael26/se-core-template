# Deferred rules

Rules that are **candidates** for the parent layer but haven't earned their place yet. Each was seen in only one or two reference projects, or was seen with enough variation that lifting now would force a false abstraction.

Promotion criterion: a **third active project** independently adopts the rule (or a close variant). At that point, move it into `CLAUDE.md` or `hooks.md` as appropriate, note the three sources, and delete it here.

Demotion criterion: if after two more projects none pick it up, drop it entirely.

Ground truth for why this file exists: Rule of Three. `n=2` is the danger zone — enough repetition to feel like a pattern, not enough to confirm it isn't coincidence. Extracting at n=2 locks in the wrong shape and the wrong defaults. Waiting for n=3 is cheap; unwinding a bad abstraction isn't.

---

## Rules (narrative form, lift when a third project confirms)

### Two-perspective review
**Source:** Project Alpha.
**What:** on non-trivial work, present a perfectionist critique alongside a pragmatist acceptance before proposing an action.
**Why defer:** valuable in a large multi-package product because features span multiple packages and trade-offs are routinely contested. Smaller projects may not benefit from the overhead.
**Lift when:** two more projects independently find value in the structured two-voice pattern (bringing total sources to 3).

### Fresh-eyes / new-user testing persona
**Source:** Project Alpha.
**What:** when asked to test your own output, adopt a new-user persona and walk through as if you've never seen the project.
**Why defer:** strong testing heuristic but unclear it fits every project class (e.g., an internal CLI tool has no "new user" in the normal sense).
**Lift when:** two more projects — ideally in different classes from the original multi-tenant SaaS — adopt the persona.

### Bug autopsy after fix
**Source:** Project Alpha.
**What:** after fixing a bug, explain root cause and whether a category-level prevention is possible (lint rule, test, type, invariant).
**Why defer:** requires meaningful bug voproject-zeta to be worth the ceremony. Greenfield or small projects may not hit the threshold.
**Lift when:** two more projects reach enough operational maturity to want systematic autopsies.

### PR size soft-target 400 / hard-ceiling 800
**Source:** Project Beta.
**What:** PRs should aim for ≤400 changed lines; ceiling at 800. Larger PRs require justification.
**Why defer:** the first source is a single Next.js app, while another reference project is a monorepo where cross-package refactors legitimately cross 800 lines. The numbers need per-project tuning before being a parent rule.
**Lift when:** two more projects validate *some* numeric target works cross-class (n=3 total). At that point, lift the pattern (with project override) rather than specific numbers.

### ADR numbered-sequential doc folder
**Source:** Project Beta.
**What:** `docs/adr/NNNN-<slug>.md` with a fixed template (context, decision, consequences, status).
**Why defer:** another project already captures the same decisions in tech-spec docs with a different layout. Picking either shape at n=1 each is arbitrary.
**Lift when:** two more projects converge on one of the two layouts (n=3 total on that layout); lift the winner.

### Tech-spec-check CI job
**Source:** Project Alpha.
**What:** CI blocks merges for changes past a size threshold without a corresponding tech spec doc.
**Why defer:** heavily coupled to one project's engineering program management flow. Worth lifting eventually but not yet.
**Lift when:** two more projects adopt a tech-spec requirement gate.

### PR-size-check CI job
**Source:** Project Alpha.
**What:** CI surfaces PR line count and warns past the soft target. Sibling to the PR size rule above.
**Why defer:** same reasoning as the PR-size rule — numbers need per-project tuning. Lift together with the rule it enforces.
**Lift when:** PR-size rule is lifted.

### axe-core accessibility tests in CI
**Source:** Project Beta.
**What:** automated a11y scan on every build; blocks on new violations.
**Why defer:** the source is a public marketing site where a11y is a launch-gate. An internal tool or API service may not need this floor. Better as a project-local rule for user-facing projects.
**Lift when:** two more user-facing projects adopt it *and* we can write a criterion for which projects should require it (not blanket).

---

## Meta

- Adding to this file is not a rejection. It's a parking spot.
- When adding: name the rule, cite the single source, state what would count as a third-project confirmation.
- When lifting: note which three projects confirmed, move the rule to `CLAUDE.md` or `hooks.md`, delete the entry here.
- Review cadence: every new project onboarding triggers a pass over this file. Otherwise quarterly.
