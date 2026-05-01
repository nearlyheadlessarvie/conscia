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
    .UseNpgsql("Host=localhost;Port=5432;Database=conscia;Username=conscia;Password=conscia_local")
    .Options;
using var db = new ConsciaDbContext(dbOptions);

Console.WriteLine("=== Conscia Seeder ===\n");

await SeedRds();
await SeedDynamo();
await SeedMinio();

Console.WriteLine("\n=== Seeding complete ===");

async Task SeedRds()
{
    Console.WriteLine("[RDS] Ensuring database is created...");
    await db.Database.EnsureCreatedAsync();

    if (await db.Users.AnyAsync())
    {
        Console.WriteLine("[RDS] Already seeded, skipping.");
        return;
    }

    var sqlPath = Path.Combine(AppContext.BaseDirectory, "..", "..", "..", "seed-rds.sql");
    if (!File.Exists(sqlPath))
        sqlPath = Path.Combine(Directory.GetCurrentDirectory(), "seed-rds.sql");

    if (File.Exists(sqlPath))
    {
        var sql = await File.ReadAllTextAsync(sqlPath);
        await db.Database.ExecuteSqlRawAsync(sql);
        Console.WriteLine("[RDS] Seeded 3 users, 3 subscriptions, 5 budgets, 10 receipts.");
    }
    else
    {
        Console.WriteLine($"[RDS] WARN: seed-rds.sql not found at {sqlPath}");
    }
}

async Task SeedDynamo()
{
    Console.WriteLine("[DynamoDB] Seeding transactions...");

    var aliceId = "a1b2c3d4-0001-4000-8000-000000000001";
    var bobId = "a1b2c3d4-0002-4000-8000-000000000002";
    var carolId = "a1b2c3d4-0003-4000-8000-000000000003";

    var categories = new[] { "Food", "Entertainment", "Transport", "Shopping", "Utilities" };
    var merchants = new[] { "Whole Foods", "Netflix", "Uber", "Amazon", "Starbucks", "Target", "Spotify", "Shell Gas", "DoorDash", "Gym" };
    var rand = new Random(42);

    var txnIds = new List<string>();
    var userIds = new[] { aliceId, bobId, carolId };
    var currencies = new[] { "USD", "EUR", "MXN" };
    var txnCount = 0;

    foreach (var (userId, currency) in userIds.Zip(currencies))
    {
        for (int i = 0; i < 17; i++)
        {
            var txnId = Guid.NewGuid().ToString();
            txnIds.Add(txnId);
            var date = DateTime.UtcNow.AddDays(-rand.Next(1, 30));
            var amount = Math.Round((decimal)(rand.NextDouble() * 200 + 5), 2);
            var category = categories[rand.Next(categories.Length)];
            var merchant = merchants[rand.Next(merchants.Length)];

            var item = new Dictionary<string, AttributeValue>
            {
                ["PK"] = new($"USER#{userId}"),
                ["SK"] = new($"TXN#{date:yyyy-MM-dd}#{txnId}"),
                ["Id"] = new(txnId),
                ["UserId"] = new(userId),
                ["Type"] = new("Expense"),
                ["Amount"] = new() { N = amount.ToString("G") },
                ["CurrencyCode"] = new(currency),
                ["Category"] = new(category),
                ["Merchant"] = new(merchant),
                ["Date"] = new(date.ToString("yyyy-MM-dd")),
                ["CreatedAt"] = new(date.ToString("O"))
            };

            if (i % 5 == 0)
                item["RegretLevel"] = new("Regret");

            await dynamo.PutItemAsync(new PutItemRequest { TableName = "Transactions", Item = item });
            txnCount++;
        }
    }
    Console.WriteLine($"[DynamoDB] Seeded {txnCount} transactions.");

    Console.WriteLine("[DynamoDB] Seeding AI interactions...");
    var aiCount = 0;
    foreach (var txnId in txnIds.Take(20))
    {
        var ts = DateTime.UtcNow.AddMinutes(-rand.Next(1, 10000));
        var item = new Dictionary<string, AttributeValue>
        {
            ["PK"] = new($"TXN#{txnId}"),
            ["SK"] = new($"AI#{ts:O}"),
            ["Id"] = new(Guid.NewGuid().ToString()),
            ["TransactionId"] = new(txnId),
            ["UserId"] = new(aliceId),
            ["Date"] = new(ts.ToString("yyyy-MM-dd")),
            ["DevilMsg"] = new("You work hard, you deserve this! Treat yourself."),
            ["AngelMsg"] = new("This purchase exceeds your weekly average by 40%. Consider waiting 24 hours."),
            ["NeutralMsg"] = new("This is a discretionary purchase of $45.99. Your budget has $179 remaining this month."),
            ["CreatedAt"] = new(ts.ToString("O")),
            ["TTL"] = new() { N = new DateTimeOffset(ts.AddDays(90)).ToUnixTimeSeconds().ToString() }
        };

        await dynamo.PutItemAsync(new PutItemRequest { TableName = "AIInteractions", Item = item });
        aiCount++;
    }
    Console.WriteLine($"[DynamoDB] Seeded {aiCount} AI interactions.");

    Console.WriteLine("[DynamoDB] Seeding behavior profiles...");
    foreach (var (userId, idx) in userIds.Select((u, i) => (u, i)))
    {
        var item = new Dictionary<string, AttributeValue>
        {
            ["PK"] = new($"USER#{userId}"),
            ["SK"] = new("PROFILE"),
            ["UserId"] = new(userId),
            ["PreventedPurchases"] = new() { N = (rand.Next(1, 20) + idx * 5).ToString() },
            ["Overrides"] = new() { N = (rand.Next(0, 10) + idx * 2).ToString() },
            ["Regrets"] = new() { N = (rand.Next(0, 5) + idx).ToString() }
        };

        await dynamo.PutItemAsync(new PutItemRequest { TableName = "BehaviorProfiles", Item = item });
    }
    Console.WriteLine("[DynamoDB] Seeded 3 behavior profiles.");

    Console.WriteLine("[DynamoDB] Seeding outbox events...");
    for (int i = 0; i < 5; i++)
    {
        var aggId = Guid.NewGuid().ToString();
        var ts = DateTime.UtcNow.AddMinutes(-rand.Next(1, 500));
        var payload = JsonSerializer.Serialize(new { BudgetId = Guid.NewGuid(), Delta = Math.Round((decimal)(rand.NextDouble() * 100), 2) });

        var item = new Dictionary<string, AttributeValue>
        {
            ["PK"] = new($"AGG#{aggId}"),
            ["SK"] = new($"EVENT#{ts:O}"),
            ["Id"] = new(Guid.NewGuid().ToString()),
            ["AggregateId"] = new(aggId),
            ["EventType"] = new("TransactionCreated"),
            ["Payload"] = new(payload),
            ["CreatedAt"] = new(ts.ToString("O")),
            ["TTL"] = new() { N = new DateTimeOffset(ts.AddDays(7)).ToUnixTimeSeconds().ToString() }
        };

        if (i < 3)
            item["ProcessedAt"] = new(DateTime.UtcNow.ToString("O"));
        else
            item["Status"] = new("PENDING");

        await dynamo.PutItemAsync(new PutItemRequest { TableName = "OutboxEvents", Item = item });
    }
    Console.WriteLine("[DynamoDB] Seeded 5 outbox events (3 processed, 2 pending).");

    Console.WriteLine("[DynamoDB] Seeding in-app alerts...");
    foreach (var userId in userIds.Take(2))
    {
        var ts = DateTime.UtcNow.AddHours(-rand.Next(1, 48));
        var item = new Dictionary<string, AttributeValue>
        {
            ["PK"] = new($"USER#{userId}"),
            ["SK"] = new($"ALERT#{ts:O}"),
            ["Id"] = new(Guid.NewGuid().ToString()),
            ["UserId"] = new(userId),
            ["TriggerName"] = new("BudgetWarning"),
            ["Title"] = new("Budget Warning: Food"),
            ["Message"] = new("You've spent 85% of your Food budget this month."),
            ["CreatedAt"] = new(ts.ToString("O")),
            ["TTL"] = new() { N = new DateTimeOffset(ts.AddDays(7)).ToUnixTimeSeconds().ToString() }
        };

        await dynamo.PutItemAsync(new PutItemRequest { TableName = "InAppAlerts", Item = item });
    }
    Console.WriteLine("[DynamoDB] Seeded 2 in-app alerts.");
}

async Task SeedMinio()
{
    Console.WriteLine("[MinIO] Ensuring bucket exists...");
    const string bucket = "conscia-receipts";

    try
    {
        await s3.PutBucketAsync(new PutBucketRequest { BucketName = bucket });
    }
    catch (AmazonS3Exception ex) when (ex.ErrorCode == "BucketAlreadyOwnedByYou" || ex.ErrorCode == "BucketAlreadyExists")
    {
        // Bucket exists
    }

    Console.WriteLine("[MinIO] Uploading placeholder receipt images...");
    var receiptPaths = new[]
    {
        "receipts/alice/r001.jpg", "receipts/alice/r002.jpg", "receipts/alice/r003.jpg",
        "receipts/alice/r004.jpg", "receipts/alice/r005.jpg",
        "receipts/carol/r006.jpg", "receipts/carol/r007.jpg", "receipts/carol/r008.jpg",
        "receipts/carol/r009.jpg", "receipts/carol/r010.jpg"
    };

    foreach (var key in receiptPaths)
    {
        var content = $"placeholder-receipt-image:{key}:{DateTime.UtcNow:O}";
        await s3.PutObjectAsync(new PutObjectRequest
        {
            BucketName = bucket,
            Key = key,
            ContentBody = content,
            ContentType = "text/plain"
        });
    }
    Console.WriteLine($"[MinIO] Uploaded {receiptPaths.Length} placeholder receipts.");
}
