// ESLint flat config (ESLint 9+) with the rules from the React Native stack kit.
// Install: npm i -D eslint typescript-eslint eslint-plugin-react-hooks
import tseslint from 'typescript-eslint';
import reactHooks from 'eslint-plugin-react-hooks';

export default tseslint.config(
  { ignores: ['android', 'ios', '.expo', 'dist', 'coverage'] },
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
    // Tokens belong in secure storage; only the storage module may use AsyncStorage.
    // Adjust the folder name to your project.
    files: ['src/**/*.{ts,tsx}'],
    ignores: ['src/storage/**'],
    rules: {
      'no-restricted-imports': ['error', {
        paths: [{
          name: '@react-native-async-storage/async-storage',
          message: 'Use the storage module. Tokens and secrets go in secure storage, never AsyncStorage.',
        }],
      }],
    },
  },
);
