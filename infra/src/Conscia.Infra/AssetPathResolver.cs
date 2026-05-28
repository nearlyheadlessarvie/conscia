namespace Conscia.Infra;

public static class AssetPathResolver
{
    public static string ResolveRepositoryFile(string relativePath)
    {
        var infraRoot = FindInfraRoot();
        var repositoryRoot = Directory.GetParent(infraRoot)?.FullName
            ?? throw new InvalidOperationException("Could not locate the repository root from the infra directory.");
        var filePath = Path.GetFullPath(Path.Combine(repositoryRoot, relativePath));
        if (!File.Exists(filePath))
        {
            throw new InvalidOperationException($"Missing repository file at '{filePath}'.");
        }

        return filePath;
    }

    public static string ResolvePublishedAsset(string relativePath, string placeholderName)
    {
        var infraRoot = FindInfraRoot();
        var assetPath = Path.GetFullPath(Path.Combine(infraRoot, relativePath));
        if (Directory.Exists(assetPath))
        {
            return assetPath;
        }

        if (!AllowPlaceholderAssets())
        {
            throw new InvalidOperationException(
                $"Missing published asset at '{assetPath}'. Publish release binaries before deploying runtime stacks.");
        }

        var placeholderPath = Path.Combine(
            infraRoot,
            "src",
            "Conscia.Infra",
            ".asset-placeholders",
            placeholderName);

        Directory.CreateDirectory(placeholderPath);
        var markerPath = Path.Combine(placeholderPath, "placeholder.txt");
        if (!File.Exists(markerPath))
        {
            File.WriteAllText(
                markerPath,
                $"Placeholder asset for {placeholderName}. Publish release binaries before deploying runtime stacks.");
        }

        return placeholderPath;
    }

    private static bool AllowPlaceholderAssets()
    {
        return string.Equals(
            Environment.GetEnvironmentVariable("CONSCIA_ALLOW_PLACEHOLDER_ASSETS"),
            "true",
            StringComparison.OrdinalIgnoreCase);
    }

    private static string FindInfraRoot()
    {
        var current = new DirectoryInfo(Directory.GetCurrentDirectory());
        while (current is not null)
        {
            if (File.Exists(Path.Combine(current.FullName, "src", "Conscia.Infra", "Conscia.Infra.csproj")))
            {
                return current.FullName;
            }

            if (File.Exists(Path.Combine(current.FullName, "infra", "src", "Conscia.Infra", "Conscia.Infra.csproj")))
            {
                return Path.Combine(current.FullName, "infra");
            }

            current = current.Parent;
        }

        throw new InvalidOperationException(
            "Could not locate the infra root. Run CDK from the repository root or the infra directory.");
    }
}
