namespace Conscia.Api.Versioning;

public sealed record AppVersionMetadata(int Major, int Minor, int Patch, int Build)
    : IComparable<AppVersionMetadata>
{
    public static bool TryParse(string? value, out AppVersionMetadata? version)
    {
        version = null;
        if (string.IsNullOrWhiteSpace(value))
        {
            return false;
        }

        var parts = value.Split('+', 2, StringSplitOptions.TrimEntries);
        if (!Version.TryParse(parts[0], out var semantic))
        {
            return false;
        }

        var build = parts.Length == 2 && int.TryParse(parts[1], out var parsedBuild)
            ? parsedBuild
            : 0;

        version = new AppVersionMetadata(
            semantic.Major,
            semantic.Minor,
            semantic.Build,
            build);
        return true;
    }

    public int CompareTo(AppVersionMetadata? other)
    {
        if (other is null)
        {
            return 1;
        }

        var comparison = Major.CompareTo(other.Major);
        if (comparison != 0)
        {
            return comparison;
        }

        comparison = Minor.CompareTo(other.Minor);
        if (comparison != 0)
        {
            return comparison;
        }

        comparison = Patch.CompareTo(other.Patch);
        if (comparison != 0)
        {
            return comparison;
        }

        return Build.CompareTo(other.Build);
    }
}
