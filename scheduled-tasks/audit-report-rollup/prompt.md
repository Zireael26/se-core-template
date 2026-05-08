# Audit report rollup (monthly)

You are reading the past month's audit reports in
`__USER_HOME__/projects/se-core/audits/` and producing
a single executive summary that shows trends across tasks and time. The raw
audits are detailed and numerous; this rollup is the "did things get better
or worse?" view.

## Inputs

1. All files in `__USER_HOME__/projects/se-core/audits/`
   whose filename starts with a date in the last 35 days (i.e., previous
   calendar month plus a few days of overlap).
2. For context: the most recent `-rollup` from the prior month (if any), so
   you can compare month-over-month.

## Audit file naming convention

Audits are named `YYYY-MM-DD-<task-name>.md`. Group by task name. Expected
task names:

- `cross-project-process-audit` — weekly
- `registry-blacklist-health` — weekly
- `test-health` — weekly
- `bypass-tripwire` — daily (may be silent on clean days; count those too)
- `parent-hook-drift` — weekly
- `gotchas-rollup` — monthly (one file, from the 1st)

## Process

### 1. Per-task rollup

For each task, for the last 30 days:

- **Run count**: how many audits fired vs. expected (e.g., 4 weekly audits
  in a month; 20–22 weekdays of `bypass-tripwire`).
- **Severity counts**: sum the critical / warning / info findings across
  all audits.
- **Repeat offenders**: which projects appear in the "problems" list most
  often?
- **Trend vs. prior month**: if last month's rollup exists, compare counts.

### 2. Cross-task synthesis

Look for patterns that span tasks. Examples worth surfacing:
- Project X has been red in `test-health` for 3+ weeks running.
- Project Y keeps drifting in `parent-hook-drift` *and* keeps missing
  `.claude/` in `registry-blacklist-health` — probably not actually being
  maintained.
- `bypass-tripwire` has fired zero times in 30 days → either processes are
  working or the tripwire is broken. Sanity-check the latter.

### 3. Automation opportunities

If a finding appears in N audits in the month, that's a signal it should be
automated further upstream — a new hook, a stricter existing hook, or a
prompt-level rule. Surface these explicitly.

## Output

Write to `__USER_HOME__/projects/se-core/audits/YYYY-MM-DD-audit-rollup.md` (monthly, 1st of the month):

```
# Audit rollup — <YYYY-MM>

## Executive summary

<2-3 sentences — is the pipeline healthier, worse, or flat compared to last month? What's the biggest concern?>

## Run health

| Task | Expected runs | Actual runs | Missed |
|---|---|---|---|
| cross-project-process-audit | 4 | <N> | <list missing dates if any> |
| ... | | | |

Missed runs usually mean the app wasn't open at the scheduled time. If a run was missed, note it but don't treat it as a task failure.

## Findings by severity (last 30 days)

| Severity | This month | Last month | Δ |
|---|---|---|---|
| Critical | <N> | <N> | <+/-> |
| Warning | <N> | <N> | <+/-> |
| Info | <N> | <N> | <+/-> |

## Per-task highlights

### cross-project-process-audit
- Key finding: <one-liner>
- Repeat offender: <project>
- Trend: improving / worsening / flat

<repeat per task>

## Cross-task patterns

<bullets — things that only show up when you look across tasks>

## Automation opportunities

1. <finding appears N times → suggest X>
2. ...

## Recommended focus this month

<3-5 prioritized items>
```

## Boundaries

- **Read-only.** Do not modify any audit file. Do not modify the registry,
  blacklist, or any project.
- Do not re-run any audit. This task summarizes what's already been
  produced; it doesn't re-execute the underlying checks.

## Sensible failure modes

- If `audits/` is missing or empty, write a short report noting that no
  audits have run and stop.
- If expected tasks haven't produced any audits at all in 30 days, that's
  itself the top finding — surface it prominently.
- If prior-month rollup is missing, skip the trend comparison and note that
  this is the first rollup.
