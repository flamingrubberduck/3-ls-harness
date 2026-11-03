# Stack kit: React Native (TypeScript)

Version: 0.1.0 · Owner: Engineering practice group

Sample kit: review and adapt before use. Rules for every React Native app, with Expo or the bare workflow. The project's AGENTS.md lists exact commands and anything that differs.

## Commands

Use the package manager that matches the committed lockfile. Never mix package managers and never delete the lockfile.

- Install: `npm ci` (or the pnpm/yarn equivalent)
- Type check: `npx tsc --noEmit`
- Lint: `npm run lint`
- Tests: `npm test`
- Bare workflow, after native dependency changes: `cd ios && pod install`

## Structure

- Screens compose components; data fetching and business logic live in hooks or the project's data layer.
- Platform differences go in `.ios.tsx` / `.android.tsx` files or `Platform.select`, not scattered checks.
- Expo projects that generate native folders with prebuild: never edit `ios/` or `android/` by hand; change app config or a config plugin instead.

## Rules agents often break

- Render long or growing lists with `FlatList` or `SectionList`, not `ScrollView` with `.map()`.
- Remove listeners and subscriptions in the `useEffect` cleanup function.
- Hooks only at the top level; keep `useEffect` dependency arrays complete.
- The JavaScript bundle can be extracted from the app: never put secrets or private API keys in it.
- Store tokens in secure storage (Keychain or Keystore via the project's library), not AsyncStorage.
- Adding a package with native code requires a native rebuild; say so in the PR.
- No `any`; use proper types or `unknown` with narrowing.
- Do not add or upgrade packages, or change the React Native or Expo SDK version, the bundle identifier or the app ID, without approval (company baseline).

## Checks this kit provides

Ready-made files are in this kit's `checks/` folder; projects get a copy in `.harness/kit/checks/`.

- [ ] ESLint with React Hooks rules as errors; `tsc` in strict mode
- [ ] Tests with Jest and React Native Testing Library
- [ ] CI steps: install from lockfile, type check, lint, tests, protected-test check from the company baseline

## Changelog

| Version | Change |
| --- | --- |
| 0.1.0 | Sample kit |
