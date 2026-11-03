# Checks: Flutter

| File | Put it in | Needs | Run |
| --- | --- | --- | --- |
| `analysis_options.yaml` | Repository root | `flutter_lints` dev dependency | `flutter analyze` |

It makes using a `BuildContext` after an `await` without a `mounted` check, unawaited futures and stream subscriptions that are never cancelled fail the analyzer, and skips generated files.

Also run `dart format --output=none --set-exit-if-changed .` and `flutter test` in CI.
