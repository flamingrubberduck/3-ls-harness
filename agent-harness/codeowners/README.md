# Code owners for agent-sensitive files

The company baseline says an agent must ask a human before changing CI/CD, infrastructure, dependencies or app identity. Code owners turn that rule into a merge requirement: a change to those files needs approval from a named owner, whoever made it.

Code owners are a feature of your git host, not your CI, so set them up wherever the repository lives.

| Host | File location | How to make approval required |
| --- | --- | --- |
| GitHub | `.github/CODEOWNERS` (or the repo root, or `docs/`) | Branch protection rule or ruleset: "Require review from Code Owners". Private repositories need a paid plan for branch protection. |
| GitLab | `CODEOWNERS` in the repo root, `.gitlab/` or `docs/` | Protected branch setting "Code owner approval". This is a GitLab Premium feature. |
| Bitbucket Cloud | `.bitbucket/CODEOWNERS` | Owners are added to pull requests as suggested reviewers. Owners are written as user emails or `@workspace/group:selector`, so rewrite the owner column (below). |
| Azure Repos | No CODEOWNERS file | Branch policy "Automatically included reviewers", set to Required, with path filters (below). |

## GitHub and GitLab

Copy `CODEOWNERS` from this folder, replace the `@your-org/...` teams with your own, and delete the sections for stacks the project does not use. Owners must have write access to the repository.

## Bitbucket Cloud

Use the same paths, with Bitbucket owners: a user's email, or a workspace group with a selector such as `:all` or `:least_busy(2)`. For example:

```
/.harness/                tech-lead@example.com
/bitbucket-pipelines.yml  @your-workspace/platform-team:all
package.json              @your-workspace/tech-leads:least_busy(1)
```

## Azure Repos

Add one "Automatically included reviewers" policy per owner group on your main branch, set to **Required**, and paste a path filter. Separate paths with `;`.

CI/CD and infrastructure (platform team):

```
/azure-pipelines*.yml;/.harness/*;/AGENTS.md;/CLAUDE.md;*Dockerfile*;*docker-compose*.yml;*.tf;/infra/*;/deploy/*
```

Dependencies (tech leads), trimmed to the stacks you use:

```
*package.json;*package-lock.json;*pnpm-lock.yaml;*yarn.lock;*pom.xml;*build.gradle;*build.gradle.kts;*.csproj;*Directory.Packages.props;*packages.lock.json;*requirements*.txt;*pyproject.toml;*poetry.lock;*go.mod;*go.sum;*composer.json;*composer.lock;*pubspec.yaml;*Podfile.lock;*Package.resolved
```

Mobile app identity (mobile leads):

```
*AndroidManifest.xml;*Info.plist;*.entitlements
```

Check the filters on a test pull request: Azure DevOps shows which policies apply to each pull request.
