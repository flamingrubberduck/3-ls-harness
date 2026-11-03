# Project rules (Level 3): <Project name>

Stack kit: <kit name> v<x.y.z> · Owner: <Project lead>

These rules apply only to this project, on top of the company baseline, the division rules and the stack kit.

<!-- Template guidance: replace every <...> and delete sections that do not apply. Write only what differs from the kit or what only this project knows. -->

## About this project

<Two or three sentences: what the product does, who uses it, which parts this team owns.>

## Commands

Only where they differ from the stack kit.

- Build: `<command>`
- Unit tests: `<command>`
- Run locally: `<command>`

## Client conventions

Where the client's standards differ from the kit:

- <e.g. Logging goes through the client's `<Logger>` wrapper, never directly to the platform logger.>

## Architecture and boundaries

- <e.g. Module `<A>` must not reference module `<B>`; shared types go in `<Shared>`.>
- <e.g. Generated code in `<path>` is never edited by hand.>

## Glossary

Use these client terms in code, comments and PR text.

| Term | Meaning |
| --- | --- |
| <term> | <meaning> |

## Environment and test data

- <How to get a working local environment.>
- <Where test data comes from; never production data.>

## Stricter permissions

From the AI policy record or project risk:

- <e.g. Do not touch `<path>` at all; changes there are made by the client team.>

## Approved exceptions

Any loosening of an upper-level rule, with who approved it.

| Rule | Exception | Approved by | Date |
| --- | --- | --- | --- |
| <rule> | <exception> | <level owner> | <YYYY-MM-DD> |
