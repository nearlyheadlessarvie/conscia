using Amazon.DynamoDBv2;
using Amazon.S3;
using Conscia.Infrastructure.Persistence;

namespace Conscia.Tools.Seeder.Story;

public static class StoryDemoProfile
{
    public static Task RunAsync(
        ConsciaDbContext db,
        IAmazonDynamoDB dynamo,
        IAmazonS3 s3,
        CancellationToken ct) =>
        throw new NotImplementedException("Story demo profile not implemented yet.");
}
