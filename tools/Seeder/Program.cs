using System.Text;
using System.Text.Json;
using Amazon;
using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.Model;
using Amazon.Runtime;
using Amazon.S3;
using Amazon.S3.Model;
using Conscia.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

var dynamoConfig = new AmazonDynamoDBConfig
{
    ServiceURL = "http://localhost:8000",
    AuthenticationRegion = "us-east-1"
};
var dynamo = new AmazonDynamoDBClient(new BasicAWSCredentials("local", "local"), dynamoConfig);

var s3Config = new AmazonS3Config
{
    ServiceURL = "http://localhost:9000",
    ForcePathStyle = true,
    AuthenticationRegion = "us-east-1"
};
var s3 = new AmazonS3Client(new BasicAWSCredentials("minioadmin", "minioadmin"), s3Config);

var dbOptions = new DbContextOptionsBuilder<ConsciaDbContext>()
    .UseNpgsql("Host=localhost;Port=5432;Database=conscia;Username=conscia;Password=conscia_dev")
    .Options;
using var db = new ConsciaDbContext(dbOptions);

Console.WriteLine("=== Conscia Seeder ===\n");

Console.WriteLine("[RDS] Ensuring database is created...");
await db.Database.EnsureCreatedAsync();

