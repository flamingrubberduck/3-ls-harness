# Checks: Java / Spring Boot

| File | Put it in | Needs |
| --- | --- | --- |
| `ArchitectureTest.java` | `src/test/java/<your package>/` | Test dependency `com.tngtech.archunit:archunit-junit5` |

The test runs with your normal unit tests (`./mvnw test` or `./gradlew test`). It fails the build when a controller uses a repository or a JPA entity directly, or when a class uses field injection.

Adjust `com.example.app`, `..controller..` and `..repository..` to your package names. On Spring Boot 2 (javax), change `jakarta.persistence.Entity` to `javax.persistence.Entity`.

For formatting and common bugs, add the plugins your team already standardizes on, such as Spotless and SpotBugs, and run them in the same CI job.
