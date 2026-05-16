using Amazon.CDK;
using Amazon.CDK.Assertions;
using Conscia.Infra;

namespace Conscia.Infra.Tests;

public class StackTests
{
    private static Amazon.CDK.Environment TestEnv => new()
    {
        Account = "123456789012",
        Region = "us-east-1"
    };

    private static DomainSettings TestDomainSettings => new(
        "getconscia.com",
        "www.getconscia.com",
        "api.getconscia.com",
        "Z1234567890");

    [Fact]
    public void DatabaseStack_CreatesDynamoOnlyControlPlane()
    {
        var template = CreateDatabaseTemplate();

        template.ResourceCountIs("AWS::DynamoDB::Table", 11);
        template.ResourceCountIs("AWS::RDS::DBInstance", 0);
        template.ResourceCountIs("AWS::SecretsManager::Secret", 0);
        template.HasResourceProperties("AWS::DynamoDB::Table", new Dictionary<string, object>
        {
            ["TableName"] = "ControlPlane",
            ["GlobalSecondaryIndexes"] = Match.ArrayWith([
                Match.ObjectLike(new Dictionary<string, object> { ["IndexName"] = "GSI1" }),
                Match.ObjectLike(new Dictionary<string, object> { ["IndexName"] = "GSI2" })
            ])
        });
    }

    [Fact]
    public void DatabaseStack_TransactionsTable_HasStream()
    {
        var template = CreateDatabaseTemplate();
        template.HasResourceProperties("AWS::DynamoDB::Table", new Dictionary<string, object>
        {
            ["TableName"] = "Transactions",
            ["StreamSpecification"] = new Dictionary<string, object>
            {
                ["StreamViewType"] = "NEW_AND_OLD_IMAGES"
            }
        });
    }

    [Fact]
    public void DatabaseStack_AllTables_UsePayPerRequest()
    {
        var template = CreateDatabaseTemplate();
        var tables = template.FindResources("AWS::DynamoDB::Table");
        Assert.Equal(11, tables.Count);

        foreach (var (_, resource) in tables)
        {
            var props = (IDictionary<string, object>)resource["Properties"];
            Assert.Equal("PAY_PER_REQUEST", props["BillingMode"].ToString());
        }
    }

    [Fact]
    public void StorageStack_CreatesPrivateS3BucketWithCors()
    {
        var app = new App();
        var stack = new StorageStack(app, "TestStorage", new StorageStackProps
        {
            Env = TestEnv,
            AllowedCorsOrigins = TestDomainSettings.AllowedCorsOrigins
        });
        var template = Template.FromStack(stack);

        template.ResourceCountIs("AWS::S3::Bucket", 1);
        template.HasResourceProperties("AWS::S3::Bucket", new Dictionary<string, object>
        {
            ["PublicAccessBlockConfiguration"] = new Dictionary<string, object>
            {
                ["BlockPublicAcls"] = true,
                ["BlockPublicPolicy"] = true,
                ["IgnorePublicAcls"] = true,
                ["RestrictPublicBuckets"] = true
            },
            ["CorsConfiguration"] = new Dictionary<string, object>
            {
                ["CorsRules"] = Match.ArrayWith([
                    Match.ObjectLike(new Dictionary<string, object>
                    {
                        ["AllowedOrigins"] = TestDomainSettings.AllowedCorsOrigins
                    })
                ])
            }
        });
    }

    [Fact]
    public void AuthStack_CreatesUserPoolAndClient()
    {
        var app = new App();
        var stack = new AuthStack(app, "TestAuth", new StackProps { Env = TestEnv });
        var template = Template.FromStack(stack);

        template.ResourceCountIs("AWS::Cognito::UserPool", 1);
        template.ResourceCountIs("AWS::Cognito::UserPoolClient", 1);
        template.HasResourceProperties("AWS::Cognito::UserPool", new Dictionary<string, object>
        {
            ["UserPoolName"] = "conscia-users"
        });
    }

    [Fact]
    public void AIStack_CreatesSqsQueueWithDlq()
    {
        var app = new App();
        var stack = new AIStack(app, "TestAI", new StackProps { Env = TestEnv });
        var template = Template.FromStack(stack);

        template.ResourceCountIs("AWS::SQS::Queue", 2);
        template.HasResourceProperties("AWS::SQS::Queue", new Dictionary<string, object>
        {
            ["QueueName"] = "conscia-ai-queue"
        });
        template.HasResourceProperties("AWS::SQS::Queue", new Dictionary<string, object>
        {
            ["QueueName"] = "conscia-ai-dlq"
        });
    }

    [Fact]
    public void ComputeStack_CreatesApiLambdaWithDirectDynamoAccess()
    {
        var (app, database, storage, auth, ai) = CreateCoreStacks();
        var stack = new ComputeStack(app, "C", new ComputeStackProps
        {
            Env = TestEnv,
            ReceiptBucket = storage.ReceiptBucket,
            UserPool = auth.UserPool,
            UserPoolClient = auth.UserPoolClient,
            ControlPlaneTable = database.ControlPlaneTable,
            TransactionsTable = database.TransactionsTable,
            RecurringSchedulesTable = database.RecurringSchedulesTable,
            AiInteractionsTable = database.AiInteractionsTable,
            OutboxEventsTable = database.OutboxEventsTable,
            InAppAlertsTable = database.InAppAlertsTable,
            WeeklyInsightsTable = database.WeeklyInsightsTable,
            PurchasePatternsTable = database.PurchasePatternsTable,
            MonthlyCategorySpendsTable = database.MonthlyCategorySpendsTable,
            PushDeviceTokensTable = database.PushDeviceTokensTable,
            ConscienceJourneyTable = database.ConscienceJourneyTable,
            AiQueue = ai.AiQueue,
            ApiAssetPath = CreateAssetStub("api")
        });

        Assert.NotNull(stack.ApiLambda);

        var template = Template.FromStack(stack);
        template.ResourceCountIs("AWS::Lambda::Function", 1);
        template.ResourceCountIs("AWS::EC2::SecurityGroup", 0);
        template.HasResourceProperties("AWS::Lambda::Function", new Dictionary<string, object>
        {
            ["Environment"] = new Dictionary<string, object>
            {
                ["Variables"] = Match.ObjectLike(new Dictionary<string, object>
                {
                    ["AWS__DynamoDB__ControlPlaneTable"] = Match.AnyValue(),
                    ["AWS__DynamoDB__TransactionsTable"] = Match.AnyValue()
                })
            }
        });
    }

    [Fact]
    public void OutboxStack_CreatesNonVpcLambdaWithEventSource()
    {
        var app = new App();
        var database = new DatabaseStack(app, "D", new StackProps { Env = TestEnv });
        var stack = new OutboxStack(app, "O", new OutboxStackProps
        {
            Env = TestEnv,
            ControlPlaneTable = database.ControlPlaneTable,
            TransactionsTable = database.TransactionsTable,
            OutboxEventsTable = database.OutboxEventsTable,
            InAppAlertsTable = database.InAppAlertsTable,
            MonthlyCategorySpendsTable = database.MonthlyCategorySpendsTable,
            AssetPath = CreateAssetStub("outbox"),
            DomainSettings = TestDomainSettings
        });

        Assert.NotNull(stack.OutboxLambda);

        var template = Template.FromStack(stack);
        template.ResourceCountIs("AWS::Lambda::Function", 1);
        template.ResourceCountIs("AWS::EC2::SecurityGroup", 0);
        template.HasResourceProperties("AWS::Lambda::EventSourceMapping", new Dictionary<string, object>
        {
            ["StartingPosition"] = "TRIM_HORIZON"
        });
    }

    [Fact]
    public void WebStack_WithDomain_CreatesAliasesAndRoute53Records()
    {
        var app = new App();
        var stack = new WebStack(app, "TestWeb", new WebStackProps
        {
            Env = TestEnv,
            DomainSettings = TestDomainSettings
        });
        var template = Template.FromStack(stack);

        template.ResourceCountIs("AWS::S3::Bucket", 1);
        template.ResourceCountIs("AWS::CloudFront::Distribution", 1);
        template.HasResourceProperties("AWS::CloudFront::Distribution", new Dictionary<string, object>
        {
            ["DistributionConfig"] = new Dictionary<string, object>
            {
                ["Aliases"] = Match.ArrayWith(TestDomainSettings.WebDomainNames)
            }
        });
        template.ResourceCountIs("AWS::Route53::RecordSet", 2);
    }

    [Fact]
    public void EmailStack_WithDomain_CreatesSesIdentity()
    {
        var app = new App();
        var stack = new EmailStack(app, "TestEmail", new EmailStackProps
        {
            Env = TestEnv,
            DomainSettings = TestDomainSettings
        });
        var template = Template.FromStack(stack);

        template.HasResourceProperties("AWS::SES::EmailIdentity", new Dictionary<string, object>
        {
            ["EmailIdentity"] = "getconscia.com"
        });
        template.ResourceCountIs("AWS::SES::ConfigurationSet", 1);
    }

    [Fact]
    public void ObservabilityStack_CreatesApiAndOutboxLogGroups()
    {
        var app = new App();
        var helperStack = new Stack(app, "Helper", new StackProps { Env = TestEnv });

        var api = CreateStubLambda(helperStack, "ApiStub", "conscia-api");
        var outbox = CreateStubLambda(helperStack, "OutboxStub", "conscia-outbox-processor");
        var stack = new ObservabilityStack(app, "TestObs", new ObservabilityStackProps
        {
            Env = TestEnv,
            ApiLambda = api,
            OutboxLambda = outbox
        });

        var template = Template.FromStack(stack);
        template.ResourceCountIs("AWS::Logs::LogGroup", 2);
    }

    private static Template CreateDatabaseTemplate()
    {
        var app = new App();
        var db = new DatabaseStack(app, "D", new StackProps { Env = TestEnv });
        return Template.FromStack(db);
    }

    private static (App App, DatabaseStack Database, StorageStack Storage, AuthStack Auth, AIStack Ai) CreateCoreStacks()
    {
        var app = new App();
        var database = new DatabaseStack(app, "D", new StackProps { Env = TestEnv });
        var storage = new StorageStack(app, "S", new StorageStackProps { Env = TestEnv });
        var auth = new AuthStack(app, "A", new StackProps { Env = TestEnv });
        var ai = new AIStack(app, "AI", new StackProps { Env = TestEnv });
        return (app, database, storage, auth, ai);
    }

    private static Amazon.CDK.AWS.Lambda.Function CreateStubLambda(Stack stack, string id, string functionName) =>
        new(stack, id, new Amazon.CDK.AWS.Lambda.FunctionProps
        {
            FunctionName = functionName,
            Runtime = Amazon.CDK.AWS.Lambda.Runtime.PYTHON_3_12,
            Handler = "handler.handler",
            Code = Amazon.CDK.AWS.Lambda.Code.FromInline("def handler(e,c): pass")
        });

    private static string CreateAssetStub(string name)
    {
        var path = Path.Combine(Path.GetTempPath(), "conscia-infra-tests", name);
        Directory.CreateDirectory(path);
        File.WriteAllText(Path.Combine(path, "placeholder.txt"), name);
        return path;
    }
}
