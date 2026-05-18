# Targets — obsolete-rules

Reads `__TRELLIS_PATH__/registry.md` at runtime. Target set = `registry \ blacklist`.

## Scope

- Quarterly, 1st of Jan / Apr / Jul / Oct at 09:00.
- Also triggered on demand after a major Claude / Codex model launch — the first quarter after a launch is the highest-yield run.
- Reads `core-rules/CLAUDE.md`, `core-rules/presets/*.md`, `engineering-process.md`, every `<project>/CLAUDE.md`, every `<project>/gotchas.md`. No writes.

## Thresholds (tunable)

- `STALE_EVIDENCE_DAYS = 180` — gotchas evidence older than this counts as "no recent occurrences".
- `STRONG_REQUIRES_NO_HOOK_COUPLING = true` — if a rule has a matching enforcement hook still active, the proposal is at most weak.
- `MIN_GENERATION_GAP = 1` — rule must have been introduced ≥1 major model generation before current to qualify (prevents proposing removal of rules added in the same generation).

Override by editing this file with a line like:
```
STALE_EVIDENCE_DAYS=240
```
Task reads these before running.
