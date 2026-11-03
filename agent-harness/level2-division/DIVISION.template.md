# Division rules (Level 2): <Division name>

Version: 0.1.0 · Owner: <Division harness owner>

These rules apply to every project in this division, on top of the company baseline. They add or tighten rules; they never loosen the baseline.

<!-- Template guidance: replace every <...>, delete sections that do not apply, and keep the file short. Long instruction files lower how closely agents follow them. -->

## Approved AI tools

- <Tool>: approved for <all clients | client family X>
- A project may narrow this list in its AI policy record, never widen it.

## Domain and data rules

- <e.g. No real customer financial or personal data in tests or fixtures; use the division's synthetic data set at <location>.>
- <e.g. Every change to <audit-relevant area> must keep the audit log entry.>

## Review standards

- <e.g. Agent PRs touching payment or payroll logic need 2 human reviewers.>
- <e.g. Agent PRs that change a public API contract need the tech lead's approval.>

## Shared client conventions

Keep one entry per client family that several projects share, instead of copying it into each project.

### <Client family>

- <Naming, logging, error-handling or branching standard>

## Promoted rules

Rules added here after an agent error recurred across this division's projects. Newest first.

| Date | Rule | Came from |
| --- | --- | --- |
| <YYYY-MM-DD> | <rule> | <projects where the error recurred> |
