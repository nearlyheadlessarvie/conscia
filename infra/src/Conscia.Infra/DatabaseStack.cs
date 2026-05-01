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
    public ITable BehaviorProfilesTable { get; }
    public ITable SessionCacheTable { get; }
    public ITable OutboxEventsTable { get; }
    public ITable InAppAlertsTable { get; }

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

        TransactionsTable = CreateDynamoTable("Transactions", "PK", "SK",
            [
                new GlobalSecondaryIndexProps
                {
                    IndexName = "GSI1",
                    PartitionKey = new Attribute { Name = "GSI1PK", Type = AttributeType.STRING },
                    SortKey = new Attribute { Name = "GSI1SK", Type = AttributeType.STRING },
                    ProjectionType = ProjectionType.ALL
                }
            ],
            streamSpecification: StreamViewType.NEW_AND_OLD_IMAGES);

        AiInteractionsTable = CreateDynamoTable("AIInteractions", "PK", "SK",
            [
                new GlobalSecondaryIndexProps
                {
                    IndexName = "GSI1",
                    PartitionKey = new Attribute { Name = "GSI1PK", Type = AttributeType.STRING },
                    SortKey = new Attribute { Name = "GSI1SK", Type = AttributeType.STRING },
                    ProjectionType = ProjectionType.ALL
                }
            ]);

        BehaviorProfilesTable = CreateDynamoTable("BehaviorProfiles", "PK", null);

        SessionCacheTable = CreateDynamoTable("SessionCache", "PK", "SK", timeToLiveAttribute: "TTL");

        OutboxEventsTable = CreateDynamoTable("OutboxEvents", "PK", "SK",
            [
                new GlobalSecondaryIndexProps
                {
                    IndexName = "GSI1",
                    PartitionKey = new Attribute { Name = "Status", Type = AttributeType.STRING },
                    SortKey = new Attribute { Name = "CreatedAt", Type = AttributeType.STRING },
                    ProjectionType = ProjectionType.ALL
                }
            ]);

        InAppAlertsTable = CreateDynamoTable("InAppAlerts", "PK", "SK",
            [
                new GlobalSecondaryIndexProps
                {
                    IndexName = "GSI1",
                    PartitionKey = new Attribute { Name = "GSI1PK", Type = AttributeType.STRING },
                    SortKey = new Attribute { Name = "GSI1SK", Type = AttributeType.STRING },
                    ProjectionType = ProjectionType.ALL
                }
            ],
            timeToLiveAttribute: "TTL");
    }

    private Table CreateDynamoTable(
        string name,
        string pk,
        string? sk,
        GlobalSecondaryIndexProps[]? gsis = null,
        string? timeToLiveAttribute = null,
        StreamViewType? streamSpecification = null)
    {
        var tableProps = new TableProps
        {
            TableName = $"Conscia-{name}",
            PartitionKey = new Attribute { Name = pk, Type = AttributeType.STRING },
            BillingMode = BillingMode.PAY_PER_REQUEST,
            RemovalPolicy = RemovalPolicy.DESTROY,
            PointInTimeRecoverySpecification = new PointInTimeRecoverySpecification { PointInTimeRecoveryEnabled = true }
        };

        if (sk is not null)
            tableProps.SortKey = new Attribute { Name = sk, Type = AttributeType.STRING };

        if (timeToLiveAttribute is not null)
            tableProps.TimeToLiveAttribute = timeToLiveAttribute;

        if (streamSpecification is not null)
            tableProps.Stream = streamSpecification;

        var table = new Table(this, name, tableProps);

        if (gsis is not null)
        {
            foreach (var gsi in gsis)
                table.AddGlobalSecondaryIndex(gsi);
        }

        return table;
    }
}
