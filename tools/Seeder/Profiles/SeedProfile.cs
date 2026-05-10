namespace Conscia.Tools.Seeder.Profiles;

public enum SeedProfile
{
    Default,
    StoryDemo,
}

public static class SeedProfileParser
{
    public static SeedProfile Parse(string[] args)
    {
        if (args.Length == 0)
            return SeedProfile.Default;

        return args[0].Trim().ToLowerInvariant() switch
        {
            "story-demo" => SeedProfile.StoryDemo,
            _ => throw new InvalidOperationException(
                $"Unknown seed profile '{args[0]}'. Supported profiles: default, story-demo.")
        };
    }
}
