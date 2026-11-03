# Checks: TypeScript / React

| File | Put it in | Needs |
| --- | --- | --- |
| `eslint.config.mjs` | Repository root (or merge into yours) | `eslint`, `typescript-eslint`, `eslint-plugin-react-hooks` |

It makes broken hook rules, incomplete effect dependencies and `any` fail the lint step, and stops components from importing the API client directly.

Also set `"strict": true` in `tsconfig.json` and run `npx tsc --noEmit` in CI, since ESLint does not report type errors.

If the project already has an ESLint config, merge the rules instead of replacing the file. Projects still on ESLint 8 with `.eslintrc` can use the same rule names.
