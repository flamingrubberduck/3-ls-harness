# Stack kit: C# / ASP.NET Core

Version: 0.1.0 · Owner: Engineering practice group

Sample kit: review and adapt before use. Rules for every ASP.NET Core project. The project's AGENTS.md lists exact commands and anything that differs.

## Commands

- Build: `dotnet build`
- Tests: `dotnet test`
- Formatting check: `dotnet format --verify-no-changes`

## Structure

- Controllers and minimal API handlers stay thin: validate input, call a service, map the result.
- Services are registered in `Program.cs` (or the project's extension methods) and injected. Do not create them with `new`.
- Settings are bound with the options pattern (`IOptions<T>`), not read from `IConfiguration` throughout the code.
- Data access goes through the project's `DbContext` or repository layer, never from controllers directly.

## Rules agents often break

- No `async void` except event handlers. Return `Task` and await it.
- Do not block on async code with `.Result`, `.Wait()` or `GetAwaiter().GetResult()`.
- Do not create `HttpClient` per call; use `IHttpClientFactory` or a typed client.
- `DbContext` is scoped: never register it as a singleton or share one instance across threads.
- Never edit an EF Core migration that has already been applied. Add a new migration instead.
- No secrets in `appsettings*.json`. Use user secrets locally and environment variables or the secret store elsewhere.
- Fix nullable warnings rather than suppressing them with `!` or `#nullable disable`.
- Do not change target frameworks or add NuGet packages without approval (company baseline).

## Checks this kit provides

Ready-made files are in this kit's `checks/` folder; projects get a copy in `.harness/kit/checks/`.

- [ ] `.editorconfig` plus .NET analyzers, with nullable and async-misuse warnings as errors
- [ ] Architecture tests (e.g. NetArchTest): controllers do not depend on `DbContext`
- [ ] CI steps: build, tests, format check, protected-test check from the company baseline

## Changelog

| Version | Change |
| --- | --- |
| 0.1.0 | Sample kit |
