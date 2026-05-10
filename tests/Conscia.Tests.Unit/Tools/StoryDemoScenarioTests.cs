using Conscia.Tools.Seeder.Profiles;

namespace Conscia.Tests.Unit.Tools;

public class StoryDemoScenarioTests
{
    [Theory]
    [InlineData(new string[0], SeedProfile.Default)]
    [InlineData(new[] { "story-demo" }, SeedProfile.StoryDemo)]
    public void Parse_ReturnsExpectedProfile(string[] args, SeedProfile expected)
    {
        var profile = SeedProfileParser.Parse(args);

        Assert.Equal(expected, profile);
    }
}
