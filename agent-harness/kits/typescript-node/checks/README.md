# Checks: TypeScript / Node.js

| File | Put it in | Needs |
| --- | --- | --- |
| `eslint.config.mjs` | Repository root (or merge into yours) | `eslint`, `typescript-eslint`, Node 20.11+ |

It uses type-aware linting to fail on floating promises and promises passed where they are not awaited, and adds three structure rules: configuration is read only in `src/config/`, route handlers do not import the database layer, and route handlers do not call synchronous APIs (`readFileSync` and similar).

Adjust the folder names in the last two blocks to your layout. Also set `"strict": true` in `tsconfig.json` and run `npx tsc --noEmit` in CI.
