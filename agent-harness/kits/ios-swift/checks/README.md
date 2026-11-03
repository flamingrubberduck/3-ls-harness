# Checks: iOS / Swift

| File | Put it in | Needs | Run |
| --- | --- | --- | --- |
| `.swiftlint.yml` | Repository root | SwiftLint | `swiftlint` |

It makes force unwraps, `try!` and force casts fail the lint step, and stops files under a `Views` folder from using `URLSession`.

Tests often use force unwraps on purpose. To allow them there, add a `.swiftlint.yml` in the test folder that turns `force_unwrapping` back to a warning. Also run the test scheme with `xcodebuild test` in CI, on a macOS runner.
