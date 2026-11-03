# Checks: React Native

| File | Put it in | Needs |
| --- | --- | --- |
| `eslint.config.mjs` | Repository root (or merge into yours) | `eslint`, `typescript-eslint`, `eslint-plugin-react-hooks` |

It makes broken hook rules, incomplete effect dependencies and `any` fail the lint step, and allows AsyncStorage only inside the storage module, so tokens cannot quietly end up there.

Also set `"strict": true` in `tsconfig.json` and run `npx tsc --noEmit` and `npm test` in CI. Projects created from the React Native or Expo templates may already ship an ESLint config; merge these rules into it.
