# Agent harness: company → division → project

A layered set of instructions, setup scripts and CI checks for running AI coding agents (Claude Code, Codex, Cursor and others) across many client projects.

Built for software services and outsourcing teams, where every client has a different stack, different conventions and a different AI policy, so one harness cannot fit every project. Instead, each project's agent instructions are assembled from three levels plus one stack kit. Rules flow down and can only be tightened. Recurring agent errors flow back up. And the rules that matter most are enforced by checks, not just written down.

| Level | File | Owner | Lives in |
| --- | --- | --- | --- |
| 1 · Company | `level1-company/AGENTS.md` | Engineering practice group | This repo |
| 2 · Division | `level2-division/DIVISION.template.md` → `DIVISION.md` | Division harness owner | Division repo |
| Stack kit | `kits/<stack>/AGENTS.md` | Engineering practice group | This repo, shared by all divisions |
| 3 · Project | `level3-project/*.template.md` → project files | Project lead | The client repo, or this repo if the client does not allow it |

```
.
├── level1-company/AGENTS.md     Process and safety rules for every project
├── level2-division/             Template for division rules
├── kits/<stack>/                Stack kits: rules (AGENTS.md) plus ready-made checks (checks/)
├── level3-project/              Templates: AI policy record, project rules, CLAUDE.md
├── scripts/                     init-project and build-agents-md, in Bash and PowerShell
├── checks/protected-tests.sh    CI check: fails when tests are deleted, skipped or weakened
├── ci/                          CI templates for six CI systems
└── codeowners/                  CODEOWNERS example and setup guide per git host
```

## Supported platforms

| Platform | Use |
| --- | --- |
| macOS | `bash scripts/init-project.sh` (written for the Bash 3.2 and BSD tools that ship with macOS) |
| Linux | `bash scripts/init-project.sh` |
| Windows | `pwsh scripts/init-project.ps1` (PowerShell 7), or the Bash script from Git Bash |

PowerShell 7 also runs on macOS and Linux, so mixed teams can use either script. Both produce identical files. The CI check runs on Linux CI runners with Bash and Git.

## How a project is laid out

After setup, a project contains:

```
.harness/
├── level1/AGENTS.md           Company baseline (pinned copy)
├── division/DIVISION.md       Division rules (pinned copy, optional)
├── kit/AGENTS.md              Stack kit (pinned copy)
├── kit/checks/                The kit's linter configs and architecture tests, to adopt
├── project/AGENTS.md          The project's own rules: the only level the team edits here
├── build-agents-md.sh / .ps1  Regenerates AGENTS.md
├── checks/protected-tests.sh  The CI check
└── harness.lock               Installed versions
AGENTS.md                      Generated from all levels; read by every agent
CLAUDE.md                      Imports AGENTS.md for Claude Code
```

`AGENTS.md` is generated, so every agent gets the complete instructions in one file: Codex, Cursor and others read it directly, and Claude Code reads it through `CLAUDE.md`. To change project rules, edit `.harness/project/AGENTS.md`, then run `bash .harness/build-agents-md.sh` (or `pwsh .harness/build-agents-md.ps1`). The CI templates fail when `AGENTS.md` was edited by hand or not regenerated.

## Stack kits

The repo ships with sample kits for common stacks. Each kit has an `AGENTS.md` with commands, structure rules and the mistakes agents most often make on that stack, and a `checks/` folder with the linter configs and architecture tests that enforce them.

| Kit | Stack | Ready-made checks |
| --- | --- | --- |
| `java-spring-boot` | Java, Spring Boot, Maven or Gradle | ArchUnit test |
| `dotnet-aspnet-core` | C#, ASP.NET Core, EF Core | `Directory.Build.props`, `.editorconfig`, NetArchTest test |
| `typescript-react` | TypeScript, React front-ends | ESLint config |
| `typescript-node` | TypeScript, Node.js back-ends (Express, NestJS, Fastify) | ESLint config with type-aware rules |
| `python-fastapi` | Python, FastAPI, Pydantic, Alembic | Ruff, mypy, import-linter configs |
| `go` | Go services and libraries | golangci-lint v2 config |
| `php-laravel` | PHP, Laravel | PHPStan (Larastan), Pint, Pest arch tests |
| `flutter` | Dart, Flutter (mobile) | `analysis_options.yaml` |
| `react-native` | TypeScript, React Native with Expo or bare workflow (mobile) | ESLint config |
| `android-kotlin` | Kotlin, native Android with Compose or Views (mobile) | Android Lint, detekt, Konsist test |
| `ios-swift` | Swift, native iOS with SwiftUI or UIKit (mobile) | SwiftLint config |

The samples are starting points: review each one against your own conventions before a project uses it, and grow its "Rules agents often break" list from real mistakes. Each `checks/README.md` says where every file goes and what it needs. For a stack not listed, copy `kits/_template/` to `kits/<stack>/` and fill it in. The init scripts offer every kit folder except those starting with `_`, and refuse a kit that is still the blank template.

## Start a new project

Run the init script from a checkout of this repo at a release tag and answer its questions:

```bash
bash scripts/init-project.sh       # macOS, Linux, Git Bash
pwsh scripts/init-project.ps1      # Windows (or anywhere with PowerShell 7)
```

It asks, in order:

1. **Project:** folder, name, client, project lead, stack kit, and the division's filled `DIVISION.md` (blank to skip).
2. **AI policy**, answered from the contract, NDA or client emails: does the client allow AI, where the answers come from, allowed tools, external services, data residency, whether agent files may live in the client repo, disclosure, and stricter domain rules. The answers become `projects/<name>/AI-POLICY.md` in this repo.
3. **Sign-off:** has the project lead approved the record? If not, the script stops. Run it again after sign-off; it reuses the record and only asks the remaining questions.
4. **CI:** which CI system runs the project's pull requests.
5. **Summary and confirm**, then it installs everything shown in the layout above.

If the client forbids AI, the record is marked "Excluded" and the script refuses to install, now and on every later run.

Any answer can be passed as a flag instead. Bash: `--project`, `--name`, `--client`, `--lead`, `--kit`, `--division`, `--mode`, `--ci`, `--force` (see `--help`). PowerShell: `-Project`, `-Name`, `-Client`, `-Lead`, `-Kit`, `-Division`, `-Mode`, `-CI`, `-Force` (see `Get-Help`). Without a terminal, for example in CI, every value must come from flags and the record must already be approved.

Afterwards, fill in `.harness/project/AGENTS.md`, regenerate `AGENTS.md`, then open Claude Code and run `/memory` to check it is loaded. Re-running the script refreshes the pinned levels (that is how you upgrade) and keeps the project's own rules unless you pass `--force`. If the project already had a hand-written `AGENTS.md`, the script moves it into `.harness/project/AGENTS.md` so nothing is lost.

> **`projects/` is git-ignored by default.** It holds AI policy records and project files with client and contract details. If you fork this into a private, internal repo and want those records versioned, remove `projects/` from `.gitignore` there. Never push them to a public repo.

## When the client does not allow agent files in their repo

If the policy answer is "no", the script switches to external mode by itself and refuses `--mode in-repo`. In external mode it:

- keeps all files in this repo under `projects/<name>/`,
- writes an untracked `CLAUDE.local.md` in the project that imports them by absolute path,
- adds `CLAUDE.local.md` to `.git/info/exclude`, so nothing is committed and the client's `.gitignore` stays untouched.

Claude Code asks once to approve imports from outside the project folder. Approve it for this path only. Agents that only read a repo's own `AGENTS.md`, and the CI checks, cannot be used in external mode, since nothing may be added to the client repo.

## CI checks

On every pull request, the CI templates run two checks:

- **`AGENTS.md` is up to date:** it matches what the levels generate, so nobody, human or agent, edited it by hand.
- **No deleted, skipped or weakened tests** (`checks/protected-tests.sh`): it fails on deleted test files, test files moved out of test folders, new skip, ignore or focus markers (`@Disabled`, `[Ignore]`, `it.skip`, `it.only`, `t.Skip`, `XCTSkip` and others, across all kit languages), files where more assertions were removed than added, and new assertions that always pass, such as `assertTrue(true)`.

This turns the company baseline's "never delete or skip a test to make a check pass" from an instruction into a merge requirement.

| CI | Template | Setup |
| --- | --- | --- |
| GitHub Actions | `ci/github-actions.yml` | Installed as `.github/workflows/agent-harness.yml`; make the check required |
| GitLab CI | `ci/gitlab-ci.yml` | `include:` it from `.gitlab-ci.yml` |
| Azure Pipelines | `ci/azure-pipelines.yml` | New pipeline, added as a build validation policy |
| Jenkins | `ci/Jenkinsfile.groovy` | Copy the stage into your `Jenkinsfile` |
| Bitbucket Pipelines | `ci/bitbucket-pipelines.yml` | Merge into `bitbucket-pipelines.yml` |
| CircleCI | `ci/circleci-config.yml` | Merge into `.circleci/config.yml` |

The init script copies the right template and prints the setup step. When a test change is intended, a reviewer approves it: on GitHub and GitLab by adding the label `test-change-approved`, elsewhere by re-running with `ALLOW_TEST_CHANGES=true`. Each template's header explains the exact steps.

## Code owners

The baseline also says an agent must ask a human before changing CI/CD, infrastructure, dependencies or app identity. `codeowners/CODEOWNERS` lists those files for every stack in the kits, and `codeowners/README.md` explains how to make owner approval required on GitHub, GitLab, Bitbucket Cloud and Azure Repos.

## Make it yours

- **Owners:** replace "Engineering practice group" in the file headers and the table above with whoever owns Level 1 and the kits in your organization.
- **Level 1 rules:** adjust `level1-company/AGENTS.md` to your process, for example the retry cap, the PR label (`agent-assisted`) and what needs human approval.
- **Stack kits:** adapt the samples you use, delete the ones you don't, and add your own from `kits/_template/`.
- **Approval label:** to use another name than `test-change-approved`, change it in `ci/github-actions.yml`, or set `APPROVAL_LABEL` for GitLab.
- **Versions:** each file carries a `Version:` line. Tag releases of this repo, and have projects install from a tag.

## Promoting a fix

Not every agent mistake should change the harness. Fix the harness when an error repeats or is costly, at the lowest level that covers every place it occurs.

| The error recurred in… | Fix goes to |
| --- | --- |
| Several projects on the same stack | That stack kit |
| Several projects of one division | That division's `DIVISION.md` |
| Several divisions | Level 1 |

How many projects count as "several" is left to each organization.

## Requirements

- **Scripts:** Git, plus Bash with `sed`, `awk` and `grep` (macOS and Linux include them), or PowerShell 7.
- **CI check:** a Linux runner with Bash and Git, and the full git history of the pull request (each template sets this up).
- **Kit checks:** the tools named in each kit's `checks/README.md`.
