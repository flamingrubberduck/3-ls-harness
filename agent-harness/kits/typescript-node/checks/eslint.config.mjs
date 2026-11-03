// ESLint flat config (ESLint 9+, Node 20.11+) with the rules from the Node.js stack kit.
// Install: npm i -D eslint typescript-eslint
import tseslint from 'typescript-eslint';

export default tseslint.config(
  { ignores: ['dist', 'build', 'coverage'] },
  ...tseslint.configs.recommendedTypeChecked,
  {
    languageOptions: {
      parserOptions: { projectService: true, tsconfigRootDir: import.meta.dirname },
    },
    rules: {
      '@typescript-eslint/no-floating-promises': 'error',
      '@typescript-eslint/no-misused-promises': 'error',
      '@typescript-eslint/no-explicit-any': 'error',
    },
  },
  {
    // Configuration is read once, in the config module. Adjust the folder name.
    files: ['src/**/*.ts'],
    ignores: ['src/config/**'],
    rules: {
      'no-restricted-properties': ['error', {
        object: 'process', property: 'env',
        message: 'Read configuration from the config module.',
      }],
    },
  },
  {
    // Route handlers stay thin. Adjust the folders and import patterns to your project.
    files: ['src/routes/**/*.ts', 'src/controllers/**/*.ts'],
    rules: {
      'no-restricted-imports': ['error', {
        patterns: [{
          group: ['**/db', '**/db/**', '**/repositories/**'],
          message: 'Route handlers call services; services use the database layer.',
        }],
      }],
      'no-restricted-syntax': ['error', {
        selector: 'CallExpression[callee.name=/Sync$/], CallExpression[callee.property.name=/Sync$/]',
        message: 'No synchronous I/O in request handlers.',
      }],
    },
  },
);
