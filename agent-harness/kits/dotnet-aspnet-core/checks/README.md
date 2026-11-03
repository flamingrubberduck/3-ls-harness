# Checks: C# / ASP.NET Core

| File | Put it in | Needs |
| --- | --- | --- |
| `Directory.Build.props` | Repository root (or merge into yours) | Nothing |
| `.editorconfig` | Merge into the root `.editorconfig` | `Microsoft.VisualStudio.Threading.Analyzers` package for the VSTHRD rules |
| `ArchitectureTests.cs` | Your test project | `NetArchTest.Rules` and xUnit packages |

`Directory.Build.props` makes nullable warnings fail the build and turns on the recommended .NET analyzers. The `.editorconfig` rules make unawaited calls, `async void` and blocking on async code fail the build. `ArchitectureTests.cs` fails when a controller uses EF Core directly.

Existing projects may produce many new errors at first. Turn the rules on in one pull request, fix or baseline the existing violations, then keep them as errors.
