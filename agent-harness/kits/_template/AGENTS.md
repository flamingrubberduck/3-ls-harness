# Stack kit: <Stack name>

Version: 0.1.0 · Owner: Engineering practice group

Rules for every project on this stack. The project's AGENTS.md lists exact commands and anything that differs.

<!-- Template guidance: copy this folder to kits/<stack>/ (lowercase and hyphenated, e.g. kits/spring-boot/), replace every <...>, and delete sections that do not apply. Keep the file short; long instruction files lower how closely agents follow them. -->

## Commands

- Build: `<command>`
- Unit tests: `<command>`
- Lint or static analysis: `<command>`

## Structure

- <Where each kind of code lives, e.g. layers, modules, platform-specific code>
- <How dependencies are wired, e.g. the dependency injection entry point>
- <What the UI or API layer may and may not call directly>

## Rules agents often break

Start with a few and grow this list from real agent mistakes on this stack, through the feedback loop.

- <e.g. a threading, async or lifecycle rule>
- <e.g. a build or project file the agent must not change without approval>
- Do not add packages without approval (company baseline).

## Checks this kit provides

Ready-made files are in this kit's `checks/` folder; projects get a copy in `.harness/kit/checks/`.

Turn the rules above into checks rather than relying on this file alone.

- [ ] Linter or analyzer configuration with the rules above as errors
- [ ] Architecture tests for the layering rules
- [ ] CI steps: build, unit tests, protected-test check from the company baseline

## Changelog

| Version | Change |
| --- | --- |
| 0.1.0 | <First version> |
