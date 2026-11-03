# Agent harness: company → division → project

A layered set of instructions and an init script for running AI coding agents (Claude Code and others) across many client projects.

Built for software services and outsourcing teams, where every client has a different stack, different conventions and a different AI policy, so one harness cannot fit every project. Instead, each project's agent instructions are assembled from three levels plus one stack kit. Rules flow down and can only be tightened. Recurring agent errors flow back up.

| Level | File | Owner | Lives in |
| --- | --- | --- | --- |
| 1 · Company | `level1-company/AGENTS.md` | Engineering practice group | This repo |
| 2 · Division | `level2-division/DIVISION.template.md` → `DIVISION.md` | Division harness owner | Division repo |
| Stack kit | `kits/<stack>/AGENTS.md` | Engineering practice group | This repo, shared by all divisions |
| 3 · Project | `level3-project/*.template.md` → project files | Project lead | The client repo, or this repo if the client does not allow it |

```
.
├── level1-company/AGENTS.md          Process and safety rules for every project
├── level2-division/                  Template for division rules
├── kits/                             One stack kit per folder: samples plus _template/
├── level3-project/                   Templates: AI policy record, project rules, CLAUDE.md
└── scripts/init-project.sh           Interactive setup for a new project
```

## Stack kits

The repo ships with sample kits for common stacks. Each lists commands, structure rules, the mistakes agents most often make on that stack, and the checks that should enforce them.

| Kit | Stack |
| --- | --- |
| `java-spring-boot` | Java, Spring Boot, Maven or Gradle |
| `dotnet-aspnet-core` | C#, ASP.NET Core, EF Core |
| `typescript-react` | TypeScript, React front-ends |
| `typescript-node` | TypeScript, Node.js back-ends (Express, NestJS, Fastify) |
| `python-fastapi` | Python, FastAPI, Pydantic, Alembic |
| `go` | Go services and libraries |
| `php-laravel` | PHP, Laravel |

The samples are starting points: review each one against your own conventions before a project uses it, and grow its "Rules agents often break" list from real mistakes. For a stack not listed, copy `kits/_template/` to `kits/<stack>/` and fill it in. The init script offers every kit folder except those starting with `_`, and refuses a kit that is still the blank template.

## Start a new project

Run the init script from a checkout of this repo at a release tag (use Git Bash on Windows) and answer its questions:

```bash
bash scripts/init-project.sh
```

It asks, in order:

1. **Project:** folder, name, client, project lead, stack kit, and the division's filled `DIVISION.md` (blank to skip).
2. **AI policy**, answered from the contract, NDA or client emails: does the client allow AI, where the answers come from, allowed tools, external services, data residency, whether agent files may live in the client repo, disclosure, and stricter domain rules. The answers become `projects/<name>/AI-POLICY.md` in this repo.
3. **Sign-off:** has the project lead approved the record? If not, the script stops. Run it again after sign-off; it reuses the record and only asks the remaining questions.
4. **Summary and confirm**, then it installs Level 1, the division file and the kit into `.harness/`, writes `.harness/harness.lock`, and creates the project's `AGENTS.md` and `CLAUDE.md`.

If the client forbids AI, the record is marked "Excluded" and the script refuses to install, now and on every later run.

Any answer can be passed as a flag instead (`--project`, `--name`, `--client`, `--lead`, `--kit`, `--division`, `--mode`, `--force`; see `--help`). Without a terminal, for example in CI, every value must come from flags and the record must already be approved.

Afterwards, fill in `AGENTS.md` with what only this project knows, then open Claude Code and run `/memory` to check every level is loaded. Re-running the script refreshes `.harness/` (that is how you upgrade) and asks before replacing the project's own `AGENTS.md` or `CLAUDE.md`.

> **`projects/` is git-ignored by default.** It holds AI policy records and project files with client and contract details. If you fork this into a private, internal repo and want those records versioned, remove `projects/` from `.gitignore` there. Never push them to a public repo.

## When the client does not allow agent files in their repo

If the policy answer is "no", the script switches to external mode by itself and refuses `--mode in-repo`. In external mode it:

- keeps all files in this repo under `projects/<name>/`,
- writes an untracked `CLAUDE.local.md` in the project that imports them by absolute path,
- adds `CLAUDE.local.md` to `.git/info/exclude`, so nothing is committed and the client's `.gitignore` stays untouched.

Claude Code asks once to approve imports from outside the project folder. Approve it for this path only.

## Agents other than Claude Code

Claude Code reads `CLAUDE.md`, which imports every level with `@path` imports. Other agents read `AGENTS.md` and do not follow `@` imports. For those tools, concatenate the four files into one `AGENTS.md` in the same order: Level 1, division, kit, project.

## Make it yours

- **Owners:** replace "Engineering practice group" in the file headers and the table above with whoever owns Level 1 and the kits in your organization.
- **Level 1 rules:** adjust `level1-company/AGENTS.md` to your process, for example the retry cap, the PR label (`agent-assisted`) and what needs human approval.
- **Stack kits:** adapt the samples you use, delete the ones you don't, and add your own from `kits/_template/`.
- **Versions:** each file carries a `Version:` line. Tag releases of this repo, and have projects install from a tag.

## Text is the fallback, not the control

These files are instructions the agent reads, not enforced configuration. Every rule that can be a check (branch protection, CODEOWNERS, a CI step that fails on removed or skipped tests, analyzers, architecture tests) should become one. Each kit's "Checks this kit provides" list tracks that work.

## Promoting a fix

Not every agent mistake should change the harness. Fix the harness when an error repeats or is costly, at the lowest level that covers every place it occurs.

| The error recurred in… | Fix goes to |
| --- | --- |
| Several projects on the same stack | That stack kit |
| Several projects of one division | That division's `DIVISION.md` |
| Several divisions | Level 1 |

How many projects count as "several" is left to each organization.

## Roadmap

- [ ] CI check that fails when a test is deleted or skipped
- [ ] CODEOWNERS examples for CI, infrastructure and dependency files
- [ ] Ready-made checks for each sample kit (linter configs, architecture tests)
- [ ] Sample kits for mobile stacks
- [ ] Script that concatenates the levels into one `AGENTS.md` for non-Claude agents
- [ ] PowerShell version of the init script

## Requirements

Bash, `sed`, `awk` and `git`. Tested with Bash 5 on Linux and written to also run on the Bash 3.2 that ships with macOS. On Windows, run it from Git Bash.
