# Stack kit: TypeScript / Node.js

Version: 0.1.0 · Owner: Engineering practice group

Sample kit: review and adapt before use. Rules for every Node.js back-end in TypeScript (Express, NestJS, Fastify and similar). The project's AGENTS.md lists exact commands and anything that differs.

## Commands

Use the package manager that matches the committed lockfile. Never mix package managers and never delete the lockfile.

- Install: `npm ci` (or the pnpm/yarn equivalent)
- Type check: `npx tsc --noEmit`
- Lint: `npm run lint`
- Tests: `npm test`

## Structure

- Route handlers stay thin: validate input, call a service, map the result.
- Validate every external input (request bodies, query strings, messages) at the boundary with the project's schema library.
- Configuration is read and validated once in a config module; do not read `process.env` throughout the code.
- Database access goes through the project's repository or ORM layer.

## Rules agents often break

- Never leave a promise floating: await it, return it, or handle its rejection explicitly.
- Do not use synchronous file or crypto APIs inside request handlers.
- Build SQL with parameters or the query builder, never by string concatenation.
- Do not log secrets, tokens or full request bodies that may contain personal data.
- Keep the project's module system consistent (ESM or CommonJS); do not mix `require` and `import`.
- No `any`; use proper types or `unknown` with narrowing.
- Never edit a database migration that has already been applied. Add a new one.
- Do not add, remove or upgrade packages without approval (company baseline).

## Checks this kit provides

Ready-made files are in this kit's `checks/` folder; projects get a copy in `.harness/kit/checks/`.

- [ ] ESLint with type-aware rules, including no floating promises; `tsc` in strict mode
- [ ] Import boundaries (e.g. dependency-cruiser): route handlers do not import the database layer directly
- [ ] CI steps: install from lockfile, type check, lint, tests, protected-test check from the company baseline

## Changelog

| Version | Change |
| --- | --- |
| 0.1.0 | Sample kit |
