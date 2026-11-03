package com.example.app // change to your root package

import com.lemonappdev.konsist.api.Konsist
import com.lemonappdev.konsist.api.architecture.KoArchitectureCreator.assertArchitecture
import com.lemonappdev.konsist.api.architecture.Layer
import org.junit.Test

// Architecture rules from the Android stack kit (Konsist).
// Put this in a unit test source set and adjust the package names.
class ArchitectureTest {

    @Test
    fun `ui depends only on domain, never on data sources`() {
        Konsist.scopeFromProject().assertArchitecture {
            val ui = Layer("UI", "com.example.app.ui..")
            val domain = Layer("Domain", "com.example.app.domain..")
            val data = Layer("Data", "com.example.app.data..")

            ui.dependsOn(domain)
            data.dependsOn(domain)
            domain.dependsOnNothing()
        }
    }
}
