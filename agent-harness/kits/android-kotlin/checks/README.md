# Checks: Android / Kotlin

| File | Put it in | Needs | Run |
| --- | --- | --- | --- |
| `lint.xml` | The app module folder (next to its `build.gradle`) | Nothing | `./gradlew lint` |
| `detekt.yml` | `config/detekt/detekt.yml` | detekt Gradle plugin, `buildUponDefaultConfig = true` | `./gradlew detekt` |
| `ArchitectureTest.kt` | A unit test source set | `com.lemonappdev:konsist` test dependency | `./gradlew test` |

Lint fails on hard-coded UI text, static fields that leak a Context, missing permission checks and unreviewed WebView JavaScript. detekt fails on `GlobalScope`, hard-coded dispatchers, `Thread.sleep` in coroutines and `!!`. The Konsist test fails when UI code depends on the data layer.

Adjust the Konsist package names to your layers. If the project uses feature modules instead of layer packages, write one layer rule per module.
