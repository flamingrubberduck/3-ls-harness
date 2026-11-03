# Company baseline (Level 1)

Version: 0.1.0 · Owner: Engineering practice group

These rules apply to every project. Division and project rules may add rules or tighten these, never loosen them. If two rules conflict, follow the stricter one and say which you followed.

## You may do without asking

- Read code and docs in this repository
- Build, run tests, linters and analyzers locally
- Create a branch for the task and commit to it
- Open a draft pull request

## Ask a human first

- Merging, or pushing to main, release or any protected branch
- Editing CI/CD pipelines, infrastructure, deployment or secrets configuration
- Adding, removing or upgrading a dependency (its license must fit the client contract)
- Running migrations or scripts against any shared environment
- Deleting or moving files outside the scope of the task

## Never

- Put secrets, credentials, production data or production logs into code, tests, fixtures, commit messages or your own context
- Send client code to any tool or service not listed in the project's AI policy record
- Delete a test, add a skip or ignore attribute, or weaken an assertion to make a check pass. If you believe a test is wrong, stop and explain why in a stop report.

## When a check fails

- Read the actual failure output before changing anything. Base each fix on the specific lines that failed.
- At most 3 fix attempts per failing check per task. Each attempt must use new evidence, not repeat the last idea.
- If the failure looks unrelated to your change (flaky test, missing tool, environment difference), stop instead of rewriting working code.
- After the third failed attempt, stop and write a stop report.

## Stop report

When you stop without finishing, post this in the PR or task:

```
### Agent stop report
- Task:
- Check that failed:
- Attempts: 1) ... 2) ... 3) ...
- Key lines of the last failure:
- Suspected cause:
- Category: flaky test | environment | requirement unclear | beyond agent | rule conflict | other
- What a human should look at first:
```

## Pull requests

- Fill the Owner field with the person who assigned the task. They review the PR as their own work.
- Add the `agent-assisted` label unless the project's AI policy record says not to.
- Describe what changed, why, how you tested it, and what you are unsure about.

## When the task is unclear

- Ask before writing code rather than guessing.
- If no one can answer in time, state your assumption at the top of the PR description.
