using Amazon.DynamoDBv2;
using Amazon.S3;

namespace Conscia.Tools.Seeder.Story;

public static class StoryDemoProfile
{
    public static async Task RunAsync(
        IAmazonDynamoDB dynamo,
        IAmazonS3 s3,
        CancellationToken ct)
    {
        var scenario = StoryDemoScenario.Build(DateTime.UtcNow);

        Console.WriteLine("[Dynamo] Seeding story-demo account and settings data...");
        await StoryDemoControlPlaneSeeder.SeedAsync(dynamo, scenario, ct);
        Console.WriteLine("[Dynamo] Story-demo account and settings data ready.");

        Console.WriteLine("[Dynamo] Seeding story-demo document and projection data...");
        await StoryDemoDynamoSeeder.SeedAsync(dynamo, scenario, ct);
        Console.WriteLine("[Dynamo] Story-demo document and projection data ready.");

        Console.WriteLine("[S3] No story-demo assets required for this profile.");
    }
}
