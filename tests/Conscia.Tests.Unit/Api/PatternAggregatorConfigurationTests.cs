namespace Conscia.Tests.Unit.Api;

public class PatternAggregatorConfigurationTests
{
    [Fact]
    public void Program_RegistersBehavioralInsightsDependencies()
    {
        var repoRoot = FindRepoRoot();
        var programPath = Path.Combine(repoRoot, "src", "Conscia.PatternAggregator", "Program.cs");

        var source = File.ReadAllText(programPath);

        Assert.Contains("AddScoped<IBudgetRepository, BudgetRepository>()", source);
        Assert.Contains("AddScoped<IMonthlyCategorySpendRepository, MonthlyCategorySpendRepository>()", source);
    }

    private static string FindRepoRoot()
    {
        var directory = new DirectoryInfo(AppContext.BaseDirectory);
        while (directory is not null && !Directory.Exists(Path.Combine(directory.FullName, ".git")))
        {
            directory = directory.Parent;
        }

        return directory?.FullName ?? throw new DirectoryNotFoundException("Could not locate repository root.");
    }
}
