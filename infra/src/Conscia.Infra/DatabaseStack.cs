using Amazon.CDK;
using Amazon.CDK.AWS.DynamoDB;
using Amazon.CDK.AWS.EC2;
using Amazon.CDK.AWS.RDS;
using Amazon.CDK.AWS.SecretsManager;
using Constructs;
using Attribute = Amazon.CDK.AWS.DynamoDB.Attribute;

namespace Conscia.Infra;

public class DatabaseStackProps : StackProps
{
    public required IVpc Vpc { get; set; }
    public required ISecurityGroup DbSecurityGroup { get; set; }
}

public class DatabaseStack : Stack
{
    public IDatabaseInstance DbInstance { get; }
    public ISecret DbPasswordSecret { get; }
    public ITable TransactionsTable { get; }
    public ITable AiInteractionsTable { get; }
    public ITable OutboxEventsTable { get; }
    public ITable InAppAlertsTable { get; }
    public ITable WeeklyInsightsTable { get; }
    public ITable PurchasePatternsTable { get; }

    public DatabaseStack(Construct scope, string id, DatabaseStackProps props)
        : base(scope, id, props)
    {
        DbPasswordSecret = new Secret(this, "DbPassword", new SecretProps
        {
            SecretName = "conscia/db-password",
            Description = "PostgreSQL master password for Conscia RDS",
            GenerateSecretString = new SecretStringGenerator
            {
                SecretStringTemplate = $"{{\"username\":\"{InfraConstants.DatabaseUsername}\"}}",
                GenerateStringKey = "password",
                ExcludePunctuation = true,
                PasswordLength = 32
            }
        });

        DbInstance = new DatabaseInstance(this, "ConsciaDb", new DatabaseInstanceProps
        {
            Engine = DatabaseInstanceEngine.Postgres(new PostgresInstanceEngineProps
            {
                Version = PostgresEngineVersion.VER_16_4
            }),
            InstanceType = Amazon.CDK.AWS.EC2.InstanceType.Of(InstanceClass.BURSTABLE4_GRAVITON, InstanceSize.MICRO),
            Vpc = props.Vpc,
            VpcSubnets = new SubnetSelection { SubnetType = SubnetType.PRIVATE_ISOLATED },
            SecurityGroups = [props.DbSecurityGroup],
            Credentials = Credentials.FromSecret(DbPasswordSecret),
            DatabaseName = InfraConstants.DatabaseName,
            AllocatedStorage = 20,
            MaxAllocatedStorage = 50,
            MultiAz = false,
            StorageEncrypted = true,
            BackupRetention = Duration.Days(7),
            DeletionProtection = false,
            RemovalPolicy = RemovalPolicy.DESTROY
        });

        TransactionsTable = CreateTable(
            "Transactions",
            "PK",
            "SK",
            new[]
            {
                new GlobalSecondaryIndexProps
                {
                    IndexName = "GSI-Date",
                    PartitionKey = new Attribute { Name = "UserId", Type = AttributeType.STRING },
                    SortKey = new Attribute { Name = "Date", Type = AttributeType.STRING },
                    ProjectionType = ProjectionType.ALL
                },
            },
            stream: StreamViewType.NEW_AND_OLD_IMAGES
        );

        AiInteractionsTable = CreateTable(
            "AIInteractions",
            "PK",
            "SK",
            new[]
            {
                new GlobalSecondaryIndexProps
                {
                    IndexName = "GSI-TransactionId-Date",
                    PartitionKey = new Attribute { Name = "TransactionId", Type = AttributeType.STRING },
                    SortKey = new Attribute { Name = "CreatedAt", Type = AttributeType.STRING },
                    ProjectionType = ProjectionType.ALL
                }
            }
        );

        OutboxEventsTable = CreateTable(
            "OutboxEvents",
            "PK",
            "SK",
            new[]
            {
                new GlobalSecondaryIndexProps
                {
                    IndexName = "GSI-Status-CreatedAt",
                    PartitionKey = new Attribute { Name = "Status", Type = AttributeType.STRING },
                    SortKey = new Attribute { Name = "CreatedAt", Type = AttributeType.STRING },
                    ProjectionType = ProjectionType.ALL
                }
            },
            ttl: "TTL"
        );

        InAppAlertsTable = CreateTable(
            "InAppAlerts",
            "PK",
            "SK",
            new[]
            {
                new GlobalSecondaryIndexProps
                {
                    IndexName = "GSI-Trigger-Date",
                    PartitionKey = new Attribute { Name = "TriggerName", Type = AttributeType.STRING },
                    SortKey = new Attribute { Name = "CreatedAt", Type = AttributeType.STRING },
                    ProjectionType = ProjectionType.ALL
                }
            },
            ttl: "TTL"
        );

        WeeklyInsightsTable = CreateTable(
            "WeeklyInsights",
            "PK",
            "SK"
        );

        PurchasePatternsTable = CreateTable(
            "PurchasePatterns",
            "PK",
            "SK"
        );
    }

    private Table CreateTable(
        string name,
        string pk,
        string? sk = null,
        GlobalSecondaryIndexProps[]? gsis = null,
        string? ttl = null,
        StreamViewType? stream = null)
    {
        var props = new TableProps
        {
            TableName = $"Conscia-{name}",
            PartitionKey = new Attribute { Name = pk, Type = AttributeType.STRING },
            BillingMode = BillingMode.PAY_PER_REQUEST,
            RemovalPolicy = RemovalPolicy.DESTROY,
            PointInTimeRecoverySpecification = new PointInTimeRecoverySpecification
            {
                PointInTimeRecoveryEnabled = true
            }
        };

        if (sk != null)
            props.SortKey = new Attribute { Name = sk, Type = AttributeType.STRING };

        if (ttl != null)
            props.TimeToLiveAttribute = ttl;

        if (stream != null)
            props.Stream = stream;

        var table = new Table(this, name, props);

        if (gsis != null)
        {
            foreach (var gsi in gsis)
                table.AddGlobalSecondaryIndex(gsi);
        }

        return table;
    }
}
