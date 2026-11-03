# Stack kit: TypeScript / React

Version: 0.1.0 · Owner: Engineering practice group

Sample kit: review and adapt before use. Rules for every React front-end in TypeScript. The project's AGENTS.md lists exact commands and anything that differs.

## Commands

Use the package manager that matches the committed lockfile (`package-lock.json` → npm, `pnpm-lock.yaml` → pnpm, `yarn.lock` → yarn). Never mix them and never delete the lockfile.

- Install: `npm ci` (or the pnpm/yarn equivalent)
- Type check: `npx tsc --noEmit`
- Lint: `npm run lint`
- Tests: `npm test`
- Build: `npm run build`

## Structure

- Components render; data fetching and business logic live in hooks or the project's data layer.
- Shared UI components live in one place; check for an existing component before writing a new one.
- API calls go through the project's API client, not raw `fetch` scattered across components.

## Rules agents often break

- Call hooks only at the top level of components and custom hooks, never inside conditions or loops.
- Keep `useEffect` dependency arrays complete; do not silence the lint rule to stop a re-render loop.
- Do not mutate state or props in place; create new objects and arrays.
- Use stable, unique keys for list items, not the array index, when the list can change.
- No `any`; use proper types or `unknown` with narrowing.
- Avoid `dangerouslySetInnerHTML`. If it is unavoidable, the content must be sanitized.
- Anything in the client bundle is public, including environment variables with public prefixes such as `VITE_` or `NEXT_PUBLIC_`. Never put secrets there.
- Do not add, remove or upgrade packages without approval (company baseline).

## Checks this kit provides

Ready-made files are in this kit's `checks/` folder; projects get a copy in `.harness/kit/checks/`.

- [ ] ESLint with the React Hooks rules as errors; `tsc` in strict mode
- [ ] Import boundaries (e.g. dependency-cruiser or ESLint import rules): components do not import the API client directly
- [ ] CI steps: install from lockfile, type check, lint, tests, build, protected-test check from the company baseline

## Changelog

| Version | Change |
| --- | --- |
| 0.1.0 | Sample kit |
