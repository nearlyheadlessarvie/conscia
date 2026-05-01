using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.Model;

var serviceUrl = args.Length > 0 ? args[0] : "http://localhost:8000";
var config = new AmazonDynamoDBConfig { ServiceURL = serviceUrl };
using var client = new AmazonDynamoDBClient(config);

Console.WriteLine($"Creating DynamoDB tables at {serviceUrl}...");

var tables = new (string Name, CreateTableRequest Request)[]
{
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
            new AttributeDefinition("PK", ScalarAttributeType.S),
            new AttributeDefinition("SK", ScalarAttributeType.S),
            new AttributeDefinition("Category", ScalarAttributeType.S),
            new AttributeDefinition("Date", ScalarAttributeType.S)
        ],
        GlobalSecondaryIndexes =
        [
            new GlobalSecondaryIndex
            {
                IndexName = "GSI1-Category-Date",
                KeySchema =
                [
                    new KeySchemaElement("Category", KeyType.HASH),
                    new KeySchemaElement("Date", KeyType.RANGE)
                ],
                Projection = new Projection { ProjectionType = ProjectionType.ALL }
            }
        ],
        BillingMode = BillingMode.PAY_PER_REQUEST
    }),

    ("AIInteractions", new CreateTableRequest
    {
        TableName = "AIInteractions",
        KeySchema =
        [
            new KeySchemaElement("PK", KeyType.HASH),
            new KeySchemaElement("SK", KeyType.RANGE)
        ],
        AttributeDefinitions =
        [
            new AttributeDefinition("PK", ScalarAttributeType.S),
            new AttributeDefinition("SK", ScalarAttributeType.S),
            new AttributeDefinition("UserId", ScalarAttributeType.S),
            new AttributeDefinition("Date", ScalarAttributeType.S)
        ],
        GlobalSecondaryIndexes =
        [
            new GlobalSecondaryIndex
            {
                IndexName = "GSI1-UserId-Date",
                KeySchema =
                [
                    new KeySchemaElement("UserId", KeyType.HASH),
                    new KeySchemaElement("Date", KeyType.RANGE)
                ],
                Projection = new Projection { ProjectionType = ProjectionType.ALL }
            }
        ],
        BillingMode = BillingMode.PAY_PER_REQUEST
    }),

    ("BehaviorProfiles", new CreateTableRequest
    {
        TableName = "BehaviorProfiles",
        KeySchema =
        [
            new KeySchemaElement("PK", KeyType.HASH),
            new KeySchemaElement("SK", KeyType.RANGE)
        ],
        AttributeDefinitions =
        [
            new AttributeDefinition("PK", ScalarAttributeType.S),
            new AttributeDefinition("SK", ScalarAttributeType.S)
        ],
        BillingMode = BillingMode.PAY_PER_REQUEST
    }),

    ("SessionCache", new CreateTableRequest
    {
        TableName = "SessionCache",
        KeySchema =
        [
            new KeySchemaElement("PK", KeyType.HASH)
        ],
        AttributeDefinitions =
        [
            new AttributeDefinition("PK", ScalarAttributeType.S)
        ],
        BillingMode = BillingMode.PAY_PER_REQUEST
    }),

    ("OutboxEvents", new CreateTableRequest
    {
        TableName = "OutboxEvents",
        KeySchema =
        [
            new KeySchemaElement("PK", KeyType.HASH),
            new KeySchemaElement("SK", KeyType.RANGE)
        ],
        AttributeDefinitions =
        [
            new AttributeDefinition("PK", ScalarAttributeType.S),
            new AttributeDefinition("SK", ScalarAttributeType.S),
            new AttributeDefinition("Status", ScalarAttributeType.S)
        ],
        GlobalSecondaryIndexes =
        [
            new GlobalSecondaryIndex
            {
                IndexName = "GSI1-Status",
                KeySchema =
                [
                    new KeySchemaElement("Status", KeyType.HASH),
                    new KeySchemaElement("SK", KeyType.RANGE)
                ],
                Projection = new Projection { ProjectionType = ProjectionType.ALL }
            }
        ],
        BillingMode = BillingMode.PAY_PER_REQUEST,
        StreamSpecification = new StreamSpecification
        {
            StreamEnabled = true,
            StreamViewType = StreamViewType.NEW_IMAGE
        }
    }),

    ("InAppAlerts", new CreateTableRequest
    {
        TableName = "InAppAlerts",
        KeySchema =
        [
            new KeySchemaElement("PK", KeyType.HASH),
            new KeySchemaElement("SK", KeyType.RANGE)
        ],
        AttributeDefinitions =
        [
            new AttributeDefinition("PK", ScalarAttributeType.S),
            new AttributeDefinition("SK", ScalarAttributeType.S)
        ],
        BillingMode = BillingMode.PAY_PER_REQUEST
    })
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
