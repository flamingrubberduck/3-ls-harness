# Stack kit: Android / Kotlin

Version: 0.1.0 · Owner: Engineering practice group

Sample kit: review and adapt before use. Rules for every native Android app in Kotlin, with Jetpack Compose or Views. The project's AGENTS.md lists exact commands and anything that differs.

## Commands

Use the Gradle wrapper committed in the repo.

- Build: `./gradlew assembleDebug`
- Unit tests: `./gradlew testDebugUnitTest`
- Lint: `./gradlew lint`
- Instrumented tests (need a device or emulator): `./gradlew connectedDebugAndroidTest`

## Structure

- MVVM: ViewModels expose state as `StateFlow`; the UI observes it and sends events back.
- Data access goes through repositories; the UI layer never calls the network or database directly.
- Use the dependency injection framework the project already uses (Hilt, Koin or other).
- User-facing text goes in `strings.xml`, not hard-coded strings.

## Rules agents often break

- No network, disk or database work on the main thread.
- Launch coroutines in `viewModelScope` or `lifecycleScope`, never `GlobalScope`.
- Never hold an Activity, Fragment or View reference in a ViewModel; it leaks memory.
- Collect flows in a lifecycle-aware way (`repeatOnLifecycle`, `collectAsStateWithLifecycle`).
- Survive configuration changes and process death: keep screen state in the ViewModel and `SavedStateHandle`.
- Never change an existing Room migration; add a new one.
- When adding a library that uses reflection, check whether it needs R8/ProGuard keep rules.
- Do not change `applicationId`, `minSdk`, `targetSdk`, `versionCode`, signing config or dependencies without approval (company baseline).

## Checks this kit provides

Ready-made files are in this kit's `checks/` folder; projects get a copy in `.harness/kit/checks/`.

- [ ] Android Lint with critical checks as errors; detekt or ktlint for Kotlin style
- [ ] Architecture tests (e.g. Konsist): UI packages do not depend on data sources directly
- [ ] CI steps: build, unit tests, lint, protected-test check from the company baseline

## Changelog

| Version | Change |
| --- | --- |
| 0.1.0 | Sample kit |
