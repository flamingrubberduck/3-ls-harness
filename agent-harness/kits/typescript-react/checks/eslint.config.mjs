// ESLint flat config (ESLint 9+) with the rules from the React stack kit.
// Install: npm i -D eslint typescript-eslint eslint-plugin-react-hooks
import tseslint from 'typescript-eslint';
import reactHooks from 'eslint-plugin-react-hooks';

export default tseslint.config(
  { ignores: ['dist', 'build', 'coverage'] },
  ...tseslint.configs.recommended,
  {
    files: ['**/*.{ts,tsx}'],
    plugins: { 'react-hooks': reactHooks },
    rules: {
      'react-hooks/rules-of-hooks': 'error',
      'react-hooks/exhaustive-deps': 'error',
      '@typescript-eslint/no-explicit-any': 'error',
    },
  },
  {
    // Components go through hooks or the data layer, not the API client.
    // Adjust the folder and the import patterns to your project.
    files: ['src/components/**/*.{ts,tsx}'],
    rules: {
      'no-restricted-imports': ['error', {
        patterns: [{
          group: ['**/api', '**/api/**', '@/api', '@/api/**'],
          message: 'Call the API through a hook or the data layer, not from components.',
        }],
      }],
    },
  },
);
