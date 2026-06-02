using Amazon.CDK;
using Amazon.CDK.AWS.DynamoDB;
using Constructs;
using Attribute = Amazon.CDK.AWS.DynamoDB.Attribute;

namespace Conscia.Infra;

public class DatabaseStack : Stack
{
    private const string LegacyTransactionsStreamExportId = "ExportsOutputFnGetAttTransactions098C5767StreamArn0D21F37C";
    private const string LegacyTransactionsStreamExportName = $"Conscia-Database:{LegacyTransactionsStreamExportId}";

    public ITable ControlPlaneTable { get; }
    public ITable TransactionsTable { get; }
    public ITable RecurringSchedulesTable { get; }
    public ITable AiInteractionsTable { get; }
    public ITable OutboxEventsTable { get; }
    public ITable InAppAlertsTable { get; }
    public ITable WeeklyInsightsTable { get; }
    public ITable PurchasePatternsTable { get; }
    public ITable MonthlyCategorySpendsTable { get; }
    public ITable PushDeviceTokensTable { get; }
    public ITable ConscienceJourneyTable { get; }
    public ITable EmailSuppressionsTable { get; }

    public DatabaseStack(Construct scope, string id, IStackProps? props = null)
        : base(scope, id, props)
    {
        ControlPlaneTable = CreateTable(
            "ControlPlane",
            "PK",
            "SK",
            [
                new GlobalSecondaryIndexProps
                {
                    IndexName = "GSI1",
                    PartitionKey = new Attribute { Name = "GSI1PK", Type = AttributeType.STRING },
                    SortKey = new Attribute { Name = "GSI1SK", Type = AttributeType.STRING },
                    ProjectionType = ProjectionType.ALL
                },
                new GlobalSecondaryIndexProps
                {
                    IndexName = "GSI2",
                    PartitionKey = new Attribute { Name = "GSI2PK", Type = AttributeType.STRING },
                    SortKey = new Attribute { Name = "GSI2SK", Type = AttributeType.STRING },
                    ProjectionType = ProjectionType.ALL
                }
            ]);

        TransactionsTable = CreateTable(
            "Transactions",
            "PK",
            "SK",
            [
                new GlobalSecondaryIndexProps
                {
                    IndexName = "GSI-UserId-Category-Date",
                    PartitionKey = new Attribute { Name = "UserId", Type = AttributeType.STRING },
                    SortKey = new Attribute { Name = "GSI1SK", Type = AttributeType.STRING },
                    ProjectionType = ProjectionType.ALL
                },
            ],
            stream: StreamViewType.NEW_AND_OLD_IMAGES);

        RecurringSchedulesTable = CreateTable("RecurringSchedules", "PK", "SK");

        AiInteractionsTable = CreateTable(
            "AIInteractions",
            "PK",
            "SK",
            [
                new GlobalSecondaryIndexProps
                {
                    IndexName = "GSI-TransactionId-Date",
                    PartitionKey = new Attribute { Name = "TransactionId", Type = AttributeType.STRING },
                    SortKey = new Attribute { Name = "CreatedAt", Type = AttributeType.STRING },
                    ProjectionType = ProjectionType.ALL
                }
            ]);

        OutboxEventsTable = CreateTable(
            "OutboxEvents",
            "PK",
            "SK",
            [
                new GlobalSecondaryIndexProps
                {
                    IndexName = "GSI-Status-CreatedAt",
                    PartitionKey = new Attribute { Name = "Status", Type = AttributeType.STRING },
                    SortKey = new Attribute { Name = "CreatedAt", Type = AttributeType.STRING },
                    ProjectionType = ProjectionType.ALL
                }
            ],
            ttl: "TTL",
            stream: StreamViewType.NEW_AND_OLD_IMAGES);

        InAppAlertsTable = CreateTable(
            "InAppAlerts",
            "PK",
            "SK",
            [
                new GlobalSecondaryIndexProps
                {
                    IndexName = "GSI-Trigger-Date",
                    PartitionKey = new Attribute { Name = "TriggerName", Type = AttributeType.STRING },
                    SortKey = new Attribute { Name = "CreatedAt", Type = AttributeType.STRING },
                    ProjectionType = ProjectionType.ALL
                }
            ],
            ttl: "TTL");

        WeeklyInsightsTable = CreateTable("WeeklyInsights", "PK", "SK");
        PurchasePatternsTable = CreateTable("PurchasePatterns", "PK", "SK");
        MonthlyCategorySpendsTable = CreateTable("MonthlyCategorySpends", "PK", "SK");
        PushDeviceTokensTable = CreateTable("PushDeviceTokens", "PK", "SK");
        ConscienceJourneyTable = CreateTable("ConscienceJourney", "PK", "SK");
        EmailSuppressionsTable = CreateTable("EmailSuppressions", "PK");

        var legacyTransactionsStreamExport = new CfnOutput(this, "LegacyTransactionsStreamArnExport", new CfnOutputProps
        {
            Value = TransactionsTable.TableStreamArn!,
            ExportName = LegacyTransactionsStreamExportName
        });
        legacyTransactionsStreamExport.OverrideLogicalId(LegacyTransactionsStreamExportId);
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
            TableName = name,
            PartitionKey = new Attribute { Name = pk, Type = AttributeType.STRING },
            BillingMode = BillingMode.PAY_PER_REQUEST,
            RemovalPolicy = RemovalPolicy.RETAIN,
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
