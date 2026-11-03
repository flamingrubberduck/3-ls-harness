package com.example.app; // change to your root package

import com.tngtech.archunit.core.importer.ImportOption;
import com.tngtech.archunit.junit.AnalyzeClasses;
import com.tngtech.archunit.junit.ArchTest;
import com.tngtech.archunit.lang.ArchRule;
import com.tngtech.archunit.library.GeneralCodingRules;

import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.noClasses;

/**
 * Architecture rules from the Spring Boot stack kit. Put this under src/test/java
 * and adjust the package names to match your project.
 */
@AnalyzeClasses(packages = "com.example.app", importOptions = ImportOption.DoNotIncludeTests.class)
class ArchitectureTest {

    @ArchTest
    static final ArchRule controllers_do_not_use_repositories =
            noClasses().that().resideInAPackage("..controller..")
                    .should().dependOnClassesThat().resideInAPackage("..repository..")
                    .because("controllers call services; services use repositories");

    @ArchTest
    static final ArchRule controllers_do_not_expose_entities =
            noClasses().that().resideInAPackage("..controller..")
                    .should().dependOnClassesThat().areAnnotatedWith("jakarta.persistence.Entity")
                    .because("controllers accept and return DTOs, never JPA entities");

    @ArchTest
    static final ArchRule no_field_injection = GeneralCodingRules.NO_CLASSES_SHOULD_USE_FIELD_INJECTION;
}
