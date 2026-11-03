# Stack kit: Flutter

Version: 0.1.0 · Owner: Engineering practice group

Sample kit: review and adapt before use. Rules for every Flutter app. The project's AGENTS.md lists exact commands and anything that differs.

## Commands

- Dependencies: `flutter pub get`
- Analyze: `flutter analyze`
- Format check: `dart format --output=none --set-exit-if-changed .`
- Tests: `flutter test`
- Code generation (if the project uses it): `dart run build_runner build --delete-conflicting-outputs`

## Structure

- Widgets render; business logic lives in the project's state management layer.
- Use the state management approach the project already uses (Provider, Riverpod, Bloc or other). Never introduce a second one.
- Platform-specific code stays in `android/` and `ios/` or behind existing plugins and platform channels.
- User-facing text goes through the project's localization setup, not hard-coded strings.

## Rules agents often break

- After an `await`, check `mounted` (or `context.mounted`) before using `BuildContext` or calling `setState`.
- Dispose what you create: controllers, focus nodes, stream subscriptions, animation controllers.
- Keep `build()` cheap: no network calls, heavy computation or object creation that belongs in state.
- Use `const` constructors wherever possible.
- Never edit generated files (`*.g.dart`, `*.freezed.dart`); change the source and regenerate.
- Do not change `pubspec.yaml` dependencies, the app ID or bundle identifier, minimum SDK versions or signing settings without approval (company baseline).

## Checks this kit provides

Ready-made files are in this kit's `checks/` folder; projects get a copy in `.harness/kit/checks/`.

- [ ] `analysis_options.yaml` based on `flutter_lints`, with stricter rules raised to errors
- [ ] Import boundaries (e.g. custom lint rules): widgets do not import the data layer directly
- [ ] CI steps: pub get, analyze, format check, tests, protected-test check from the company baseline

## Changelog

| Version | Change |
| --- | --- |
| 0.1.0 | Sample kit |
