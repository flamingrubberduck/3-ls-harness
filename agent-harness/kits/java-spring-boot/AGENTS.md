# Stack kit: Java / Spring Boot

Version: 0.1.0 · Owner: Engineering practice group

Sample kit: review and adapt before use. Rules for every Spring Boot project. The project's AGENTS.md lists exact commands and anything that differs.

## Commands

Use the build wrapper committed in the repo, never a globally installed Maven or Gradle.

- Maven: `./mvnw verify` (build and all tests), `./mvnw test` (unit tests)
- Gradle: `./gradlew build` (build and all tests), `./gradlew test` (unit tests)

## Structure

- Layers: controller → service → repository. Controllers never call repositories directly.
- Use constructor injection. No field injection with `@Autowired`.
- Configuration lives in `application.yml` (or `.properties`) and is read through `@ConfigurationProperties` classes, not scattered `@Value` lookups.
- Controllers accept and return DTOs, never JPA entities.

## Rules agents often break

- `@Transactional` works through proxies: it has no effect on private methods or on calls from another method in the same class.
- Watch for N+1 queries when touching lazy-loaded relations; use fetch joins or entity graphs where a list needs related data.
- Never edit a Flyway or Liquibase migration that has already been applied. Add a new migration instead.
- No secrets in `application.yml` or test resources. Use environment variables or the project's secret store.
- Do not catch `Exception` or `Throwable` just to log and continue. Handle specific exceptions or let them reach the global handler.
- Do not call `Optional.get()` without checking; use `orElseThrow` with a meaningful exception.
- Do not add or upgrade dependencies, or change the Spring Boot parent version, without approval (company baseline).

## Checks this kit provides

Ready-made files are in this kit's `checks/` folder; projects get a copy in `.harness/kit/checks/`.

- [ ] Checkstyle or Spotless for formatting, SpotBugs or PMD for common bugs
- [ ] ArchUnit tests: controllers do not depend on repositories; no entity types in controller signatures
- [ ] CI steps: `verify`/`build`, protected-test check from the company baseline

## Changelog

| Version | Change |
| --- | --- |
| 0.1.0 | Sample kit |
