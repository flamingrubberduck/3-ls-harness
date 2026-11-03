# Checks: <Stack name>

Put the files that enforce this kit's rules in this folder: linter configuration, architecture tests, formatter settings. The init script copies them to `.harness/kit/checks/` in each project, where the team adopts them into the codebase.

| File | Put it in | Needs | Run |
| --- | --- | --- | --- |
| `<file>` | `<location in the project>` | `<packages or tools>` | `<command>` |

For each rule in the kit's "Rules agents often break" list, say which file enforces it. Rules with no check stay review points until someone writes one.
