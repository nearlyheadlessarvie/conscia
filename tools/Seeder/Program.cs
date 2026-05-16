using Amazon.DynamoDBv2;
using Amazon.Runtime;
using Amazon.S3;
using Conscia.Tools.Seeder.Profiles;
using Conscia.Tools.Seeder.Story;

var profile = SeedProfileParser.Parse(args);

Console.WriteLine("=== Conscia Seeder ===\n");
Console.WriteLine($"[Seeder] Profile: {profile}");

var dynamoConfig = new AmazonDynamoDBConfig
{
    ServiceURL = "http://localhost:8000",
    AuthenticationRegion = "ap-southeast-1"
};
var dynamo = new AmazonDynamoDBClient(new BasicAWSCredentials("local", "local"), dynamoConfig);

var s3Config = new AmazonS3Config
{
    ServiceURL = "http://localhost:9000",
    ForcePathStyle = true,
    AuthenticationRegion = "ap-southeast-1"
};
var s3 = new AmazonS3Client(new BasicAWSCredentials("minioadmin", "minioadmin"), s3Config);

switch (profile)
{
    case SeedProfile.Default:
        Console.WriteLine("[Seeder] Default profile not yet expanded in this task.");
        break;
    case SeedProfile.StoryDemo:
        await StoryDemoProfile.RunAsync(dynamo, s3, CancellationToken.None);
        break;
}
