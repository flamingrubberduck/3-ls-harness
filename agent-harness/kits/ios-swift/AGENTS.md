# Stack kit: iOS / Swift

Version: 0.1.0 · Owner: Engineering practice group

Sample kit: review and adapt before use. Rules for every native iOS app in Swift, with SwiftUI or UIKit. The project's AGENTS.md lists the exact scheme, simulator and commands.

## Commands

- Build: `xcodebuild -scheme <Scheme> -destination 'platform=iOS Simulator,name=<Device>' build`
- Tests: `xcodebuild -scheme <Scheme> -destination 'platform=iOS Simulator,name=<Device>' test`
- Lint: `swiftlint` (if the project uses it)

## Structure

- Views render; state and logic live in view models or the project's chosen architecture.
- Networking goes through the project's API client; views never call `URLSession` directly.
- Dependencies come through the package manager the project already uses (Swift Package Manager or CocoaPods).

## Rules agents often break

- Update UI only on the main actor (`@MainActor` or the main queue).
- Avoid retain cycles: capture `[weak self]` in escaping closures that self stores or that outlive it.
- No force unwraps (`!`) or `try!` outside tests; handle the optional or the error.
- A new source file must also be added to the right Xcode target. Check that it builds, not just that the file exists.
- Do not hand-edit `project.pbxproj` beyond what the change needs; never reformat it.
- Store tokens in the Keychain, not `UserDefaults`. No secrets in source code or `Info.plist`.
- Fix concurrency warnings properly; do not silence them with `@unchecked Sendable`.
- Do not change the bundle identifier, signing, entitlements, deployment target or dependencies without approval (company baseline).

## Checks this kit provides

Ready-made files are in this kit's `checks/` folder; projects get a copy in `.harness/kit/checks/`.

- [ ] SwiftLint with force unwrap and force try rules as errors
- [ ] Module or folder boundaries checked in review or with custom lint rules: views do not import the networking layer
- [ ] CI steps: build, tests, lint, protected-test check from the company baseline

## Changelog

| Version | Change |
| --- | --- |
| 0.1.0 | Sample kit |
