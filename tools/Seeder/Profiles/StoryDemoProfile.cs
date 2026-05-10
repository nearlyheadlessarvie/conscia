using Amazon.DynamoDBv2;
using Amazon.S3;
using Conscia.Infrastructure.Persistence;

namespace Conscia.Tools.Seeder.Story;

public static class StoryDemoProfile
{
    public static async Task RunAsync(
        ConsciaDbContext db,
        IAmazonDynamoDB dynamo,
        IAmazonS3 s3,
        CancellationToken ct)
    {
        var scenario = StoryDemoScenario.Build(DateTime.UtcNow);

        Console.WriteLine("[RDS] Seeding story-demo relational data...");
        await StoryDemoRdsSeeder.SeedAsync(db, scenario, ct);
        Console.WriteLine("[RDS] Story-demo relational data ready.");

        Console.WriteLine("[Dynamo] Seeding story-demo document and projection data...");
        await StoryDemoDynamoSeeder.SeedAsync(dynamo, scenario, ct);
        Console.WriteLine("[Dynamo] Story-demo document and projection data ready.");

        Console.WriteLine("[S3] No story-demo assets required for this profile.");
    }
}
