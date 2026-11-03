using System;
using NetArchTest.Rules;
using Xunit;

// Architecture rules from the ASP.NET Core stack kit.
// Put this in your test project and reference the API project.
public class ArchitectureTests
{
    // Any public type from the API assembly. With top-level statements, add
    // "public partial class Program { }" to Program.cs so tests can see it.
    private static readonly System.Reflection.Assembly Api = typeof(Program).Assembly;

    [Fact]
    public void Controllers_do_not_use_EF_Core_directly()
    {
        var result = Types.InAssembly(Api)
            .That().HaveNameEndingWith("Controller")
            .ShouldNot().HaveDependencyOn("Microsoft.EntityFrameworkCore")
            .GetResult();

        Assert.True(result.IsSuccessful,
            "Controllers call services, not DbContext: " +
            string.Join(", ", result.FailingTypeNames ?? Array.Empty<string>()));
    }
}
