using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.Model;

var serviceUrl = args.Length > 0 ? args[0] : "http://localhost:8000";
var config = new AmazonDynamoDBConfig { ServiceURL = serviceUrl };
using var client = new AmazonDynamoDBClient("local", "local", config);

Console.WriteLine($"Creating DynamoDB tables at {serviceUrl}...");

var tables = new (string Name, CreateTableRequest Request)[]
{
    // ---------------- TRANSACTIONS ----------------
    ("Transactions", new CreateTableRequest
    {
        TableName = "Transactions",
        KeySchema =
        [
            new KeySchemaElement("PK", KeyType.HASH),
            new KeySchemaElement("SK", KeyType.RANGE)
        ],
        AttributeDefinitions =
        [
            new("PK", ScalarAttributeType.S),
            new("SK", ScalarAttributeType.S),
            new("UserId", ScalarAttributeType.S),
            new("Date", ScalarAttributeType.S)
        ],
        GlobalSecondaryIndexes =
        [
            new GlobalSecondaryIndex
            {
                IndexName = "GSI-Date",
                KeySchema =
                [
                    new("UserId", KeyType.HASH),
                    new("Date", KeyType.RANGE)
                ],
                Projection = new Projection { ProjectionType = ProjectionType.ALL }
            }
        ],
        BillingMode = BillingMode.PAY_PER_REQUEST,
        StreamSpecification = new StreamSpecification
        {
            StreamEnabled = true,
            StreamViewType = StreamViewType.NEW_AND_OLD_IMAGES
        }
    }),

    // ---------------- AI INTERACTIONS ----------------
    ("AIInteractions", new CreateTableRequest
    {
        TableName = "AIInteractions",
        KeySchema =
        [
            new("PK", KeyType.HASH),
            new("SK", KeyType.RANGE)
        ],
        AttributeDefinitions =
        [
            new("PK", ScalarAttributeType.S),
            new("SK", ScalarAttributeType.S),
            new("TransactionId", ScalarAttributeType.S),
            new("CreatedAt", ScalarAttributeType.S)
        ],
        GlobalSecondaryIndexes =
        [
            new GlobalSecondaryIndex
            {
                IndexName = "GSI-TransactionId-Date",
                KeySchema =
                [
                    new("TransactionId", KeyType.HASH),
                    new("CreatedAt", KeyType.RANGE)
                ],
                Projection = new Projection { ProjectionType = ProjectionType.ALL }
            },
        ],
        BillingMode = BillingMode.PAY_PER_REQUEST
    }),

    // ---------------- BEHAVIOR PROFILE ----------------
    ("BehaviorProfiles", new CreateTableRequest
    {
        TableName = "BehaviorProfiles",
        KeySchema =
        [
            new("PK", KeyType.HASH)
        ],
        AttributeDefinitions =
        [
            new("PK", ScalarAttributeType.S)
        ],
        BillingMode = BillingMode.PAY_PER_REQUEST
    }),

    // ---------------- OUTBOX ----------------
    ("OutboxEvents", new CreateTableRequest
    {
        TableName = "OutboxEvents",
        KeySchema =
        [
            new("PK", KeyType.HASH),
            new("SK", KeyType.RANGE)
        ],
        AttributeDefinitions =
        [
            new("PK", ScalarAttributeType.S),
            new("SK", ScalarAttributeType.S),
            new("Status", ScalarAttributeType.S),
            new("CreatedAt", ScalarAttributeType.S)
        ],
        GlobalSecondaryIndexes =
        [
            new GlobalSecondaryIndex
            {
                IndexName = "GSI-Status-CreatedAt",
                KeySchema =
                [
                    new("Status", KeyType.HASH),
                    new("CreatedAt", KeyType.RANGE)
                ],
                Projection = new Projection { ProjectionType = ProjectionType.ALL }
            }
        ],
        BillingMode = BillingMode.PAY_PER_REQUEST
    }),

    // ---------------- WEEKLY INSIGHTS ----------------
    ("WeeklyInsights", new CreateTableRequest
    {
        TableName = "WeeklyInsights",
        KeySchema =
        [
            new("PK", KeyType.HASH),
            new("SK", KeyType.RANGE)
        ],
        AttributeDefinitions =
        [
            new("PK", ScalarAttributeType.S),
            new("SK", ScalarAttributeType.S)
        ],
        BillingMode = BillingMode.PAY_PER_REQUEST
    }),

    // ---------------- PURCHASE PATTERNS ----------------
    ("PurchasePatterns", new CreateTableRequest
    {
        TableName = "PurchasePatterns",
        KeySchema =
        [
            new KeySchemaElement("PK", KeyType.HASH),
            new KeySchemaElement("SK", KeyType.RANGE)
        ],
        AttributeDefinitions =
        [
            new("PK", ScalarAttributeType.S),
            new("SK", ScalarAttributeType.S)
        ],
        BillingMode = BillingMode.PAY_PER_REQUEST
    }),

    // ---------------- IN-APP ALERTS ----------------
    ("InAppAlerts", new CreateTableRequest
    {
        TableName = "InAppAlerts",
        KeySchema =
        [
            new("PK", KeyType.HASH),
            new("SK", KeyType.RANGE)
        ],
        AttributeDefinitions =
        [
            new("PK", ScalarAttributeType.S),
            new("SK", ScalarAttributeType.S),
            new("TriggerName", ScalarAttributeType.S),
            new("CreatedAt", ScalarAttributeType.S)
        ],
        GlobalSecondaryIndexes =
        [
            new GlobalSecondaryIndex
            {
                IndexName = "GSI-Trigger-Date",
                KeySchema =
                [
                    new("TriggerName", KeyType.HASH),
                    new("CreatedAt", KeyType.RANGE)
                ],
                Projection = new Projection { ProjectionType = ProjectionType.ALL }
            }
        ],
        BillingMode = BillingMode.PAY_PER_REQUEST
    }),

    // ---------------- SESSION CACHE ----------------
    ("SessionCache", new CreateTableRequest
    {
        TableName = "SessionCache",
        KeySchema =
        [
            new("PK", KeyType.HASH)
        ],
        AttributeDefinitions =
        [
            new("PK", ScalarAttributeType.S)
        ],
        BillingMode = BillingMode.PAY_PER_REQUEST
    }),
};

var existingTables = await client.ListTablesAsync();

foreach (var (name, request) in tables)
{
    try
    {
        if (existingTables.TableNames.Contains(name))
        {
            Console.WriteLine($"  Table '{name}' already exists, skipping.");
            continue;
        }

        await client.CreateTableAsync(request);
        Console.WriteLine($"  Created table '{name}'");

        if (name is "SessionCache" or "InAppAlerts" or "OutboxEvents")
        {
            await client.UpdateTimeToLiveAsync(new UpdateTimeToLiveRequest
            {
                TableName = name,
                TimeToLiveSpecification = new TimeToLiveSpecification
                {
                    Enabled = true,
                    AttributeName = "TTL"
                }
            });
            Console.WriteLine($"  Enabled TTL on '{name}'");
        }
    }
    catch (Exception ex)
    {
        Console.Error.WriteLine($"  Error creating table '{name}': {ex.Message}");
    }
}

Console.WriteLine("DynamoDB setup complete.");
