# Changelog

## 0.2.0

Enforcement, and support for every agent and platform.

- **Generated `AGENTS.md`:** each project's root `AGENTS.md` now combines every level, so all agents (not only Claude Code) get the full instructions. Project rules move to `.harness/project/AGENTS.md`; `CLAUDE.md` now just imports `AGENTS.md`. New `build-agents-md.sh` and `build-agents-md.ps1` regenerate it and check it in CI. Re-running the init script migrates 0.1.0 projects automatically.
- **Protected-test check:** `checks/protected-tests.sh` fails pull requests that delete, skip or weaken tests, with reviewer approval by label or variable.
- **CI templates** for GitHub Actions, GitLab CI, Azure Pipelines, Jenkins, Bitbucket Pipelines and CircleCI. The init script asks which CI the project uses and installs the template.
- **Code owners:** CODEOWNERS example and setup guide for GitHub, GitLab, Bitbucket Cloud and Azure Repos.
- **Kit checks:** every sample kit has a `checks/` folder with linter configs and architecture tests.
- **PowerShell:** `init-project.ps1` and `build-agents-md.ps1` for Windows, with the same behavior and output as the Bash scripts.
- **macOS and Linux:** the Bash scripts avoid GNU-only tool features and Bash 4 syntax, so they suit the Bash 3.2 and BSD tools that ship with macOS.

## 0.1.0

First release.

- Level 1 company baseline: permissions, data and secrets, 3-attempt retry cap, protected tests, stop report, PR ownership
- Level 2 division template
- Level 3 project templates: AI policy record, project rules, `CLAUDE.md` entry point
- Stack kit template, and sample kits for Java/Spring Boot, C#/ASP.NET Core, TypeScript/React, TypeScript/Node.js, Python/FastAPI, Go and PHP/Laravel
- Mobile sample kits for Flutter, React Native, Android/Kotlin and iOS/Swift
- `scripts/init-project.sh`: interactive setup with an AI policy gate, in-repo and external modes, and a version lock file
