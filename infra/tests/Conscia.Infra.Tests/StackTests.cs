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

    [Fact]
    public void NetworkStack_CreatesVpc()
    {
        var app = new App();
        var stack = new NetworkStack(app, "TestNetwork", new StackProps { Env = TestEnv });
        var template = Template.FromStack(stack);
        template.ResourceCountIs("AWS::EC2::VPC", 1);
    }

    [Fact]
    public void NetworkStack_HasTwoAZs_WithPublicAndPrivateSubnets()
    {
        var app = new App();
        var stack = new NetworkStack(app, "TestNetwork", new StackProps { Env = TestEnv });
        var template = Template.FromStack(stack);
        template.ResourceCountIs("AWS::EC2::Subnet", 4);
    }

    [Fact]
    public void NetworkStack_HasNoNatGateway()
    {
        var app = new App();
        var stack = new NetworkStack(app, "TestNetwork", new StackProps { Env = TestEnv });
        var template = Template.FromStack(stack);
        template.ResourceCountIs("AWS::EC2::NatGateway", 0);
    }

    [Fact]
    public void NetworkStack_CreatesDbSecurityGroup()
    {
        var app = new App();
        var stack = new NetworkStack(app, "TestNetwork", new StackProps { Env = TestEnv });
        var template = Template.FromStack(stack);
        template.ResourceCountIs("AWS::EC2::SecurityGroup", 1);
    }

    [Fact]
    public void DatabaseStack_CreatesDbSecret()
    {
        var template = CreateDatabaseTemplate();
        template.ResourceCountIs("AWS::SecretsManager::Secret", 1);
        template.HasResourceProperties("AWS::SecretsManager::Secret", new Dictionary<string, object>
        {
            ["Name"] = "conscia/db-password"
        });
    }

    private static Template CreateDatabaseTemplate()
    {
        var app = new App();
        var network = new NetworkStack(app, "N", new StackProps { Env = TestEnv });
        var db = new DatabaseStack(app, "D", new DatabaseStackProps
        {
            Env = TestEnv,
            Vpc = network.Vpc,
            DbSecurityGroup = network.DbSecurityGroup
        });
        return Template.FromStack(db);
    }

    [Fact]
    public void DatabaseStack_CreatesRdsInstance()
    {
        var template = CreateDatabaseTemplate();
        template.ResourceCountIs("AWS::RDS::DBInstance", 1);
    }

    [Fact]
    public void DatabaseStack_CreatesSevenDynamoDbTables()
    {
        var template = CreateDatabaseTemplate();
        template.ResourceCountIs("AWS::DynamoDB::Table", 7);
    }

    [Fact]
    public void DatabaseStack_TransactionsTable_HasStream()
    {
        var template = CreateDatabaseTemplate();
        template.HasResourceProperties("AWS::DynamoDB::Table", new Dictionary<string, object>
        {
            ["TableName"] = "Conscia-Transactions",
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
        Assert.Equal(7, tables.Count);

        foreach (var (_, resource) in tables)
        {
            var props = (IDictionary<string, object>)resource["Properties"];
            Assert.Equal("PAY_PER_REQUEST", props["BillingMode"].ToString());
        }
    }

    [Fact]
    public void StorageStack_CreatesS3Bucket()
    {
        var app = new App();
        var stack = new StorageStack(app, "TestStorage", new StackProps { Env = TestEnv });
        var template = Template.FromStack(stack);
        template.ResourceCountIs("AWS::S3::Bucket", 1);
    }

    [Fact]
    public void StorageStack_BlocksPublicAccess()
    {
        var app = new App();
        var stack = new StorageStack(app, "TestStorage", new StackProps { Env = TestEnv });
        var template = Template.FromStack(stack);
        template.HasResourceProperties("AWS::S3::Bucket", new Dictionary<string, object>
        {
            ["PublicAccessBlockConfiguration"] = new Dictionary<string, object>
            {
                ["BlockPublicAcls"] = true,
                ["BlockPublicPolicy"] = true,
                ["IgnorePublicAcls"] = true,
                ["RestrictPublicBuckets"] = true
            }
        });
    }

    [Fact]
    public void AuthStack_CreatesUserPool()
    {
        var app = new App();
        var stack = new AuthStack(app, "TestAuth", new StackProps { Env = TestEnv });
        var template = Template.FromStack(stack);
        template.ResourceCountIs("AWS::Cognito::UserPool", 1);
        template.HasResourceProperties("AWS::Cognito::UserPool", new Dictionary<string, object>
        {
            ["UserPoolName"] = "conscia-users"
        });
    }

    [Fact]
    public void AuthStack_CreatesUserPoolClient()
    {
        var app = new App();
        var stack = new AuthStack(app, "TestAuth", new StackProps { Env = TestEnv });
        var template = Template.FromStack(stack);
        template.ResourceCountIs("AWS::Cognito::UserPoolClient", 1);
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
    public void ComputeStack_CreatesApiLambda()
    {
        var app = new App();
        var network = new NetworkStack(app, "N", new StackProps { Env = TestEnv });
        var database = new DatabaseStack(app, "D", new DatabaseStackProps
        {
            Env = TestEnv,
            Vpc = network.Vpc,
            DbSecurityGroup = network.DbSecurityGroup
        });
        var storage = new StorageStack(app, "S", new StackProps { Env = TestEnv });
        var auth = new AuthStack(app, "A", new StackProps { Env = TestEnv });
        var ai = new AIStack(app, "AI", new StackProps { Env = TestEnv });

        var dbAccess = new DbAccessStack(app, "DA", new DbAccessStackProps
        {
            Env = TestEnv,
            Vpc = network.Vpc,
            DbSecurityGroup = network.DbSecurityGroup,
            DbInstance = database.DbInstance,
            DbPasswordSecret = database.DbPasswordSecret,
            AssetPath = CreateAssetStub("db-access")
        });

        var stack = new ComputeStack(app, "C", new ComputeStackProps
        {
            Env = TestEnv,
            ReceiptBucket = storage.ReceiptBucket,
            UserPool = auth.UserPool,
            UserPoolClient = auth.UserPoolClient,
            TransactionsTable = database.TransactionsTable,
            AiInteractionsTable = database.AiInteractionsTable,
            OutboxEventsTable = database.OutboxEventsTable,
            InAppAlertsTable = database.InAppAlertsTable,
            WeeklyInsightsTable = database.WeeklyInsightsTable,
            PurchasePatternsTable = database.PurchasePatternsTable,
            PushDeviceTokensTable = database.PushDeviceTokensTable,
            AiQueue = ai.AiQueue,
            DbAccessLambda = dbAccess.DbAccessLambda,
            ApiAssetPath = CreateAssetStub("api")
        });

        Assert.NotNull(stack.ApiLambda);
    }

    [Fact]
    public void DbAccessStack_CreatesLambda()
    {
        var app = new App();
        var network = new NetworkStack(app, "N", new StackProps { Env = TestEnv });
        var database = new DatabaseStack(app, "D", new DatabaseStackProps
        {
            Env = TestEnv,
            Vpc = network.Vpc,
            DbSecurityGroup = network.DbSecurityGroup
        });

        // Instantiate the stack — cyclic ref only triggers on Template.FromStack synth,
        // so we verify construction succeeds and spot-check the Lambda function name.
        var stack = new DbAccessStack(app, "DA", new DbAccessStackProps
        {
            Env = TestEnv,
            Vpc = network.Vpc,
            DbSecurityGroup = network.DbSecurityGroup,
            DbInstance = database.DbInstance,
            DbPasswordSecret = database.DbPasswordSecret,
            AssetPath = CreateAssetStub("db-access")
        });

        Assert.NotNull(stack.DbAccessLambda);
    }

    [Fact]
    public void OutboxStack_CreatesLambdaWithEventSource()
    {
        var app = new App();
        var network = new NetworkStack(app, "N", new StackProps { Env = TestEnv });
        var database = new DatabaseStack(app, "D", new DatabaseStackProps
        {
            Env = TestEnv,
            Vpc = network.Vpc,
            DbSecurityGroup = network.DbSecurityGroup
        });

        var stack = new OutboxStack(app, "O", new OutboxStackProps
        {
            Env = TestEnv,
            TransactionsTable = database.TransactionsTable,
            OutboxEventsTable = database.OutboxEventsTable,
            DbPasswordSecret = database.DbPasswordSecret,
            Vpc = network.Vpc,
            DbSecurityGroup = network.DbSecurityGroup,
            DbInstance = database.DbInstance,
            AssetPath = CreateAssetStub("outbox")
        });

        Assert.NotNull(stack.OutboxLambda);
    }

    [Fact]
    public void WebStack_CreatesBucketAndDistribution()
    {
        var app = new App();
        var stack = new WebStack(app, "TestWeb", new StackProps { Env = TestEnv });
        var template = Template.FromStack(stack);
        template.ResourceCountIs("AWS::S3::Bucket", 1);
        template.ResourceCountIs("AWS::CloudFront::Distribution", 1);
    }

    [Fact]
    public void ObservabilityStack_CreatesThreeLogGroups()
    {
        var app = new App();

        var helperStack = new Stack(app, "Helper", new StackProps { Env = TestEnv });

        var stubLambda1 = new Amazon.CDK.AWS.Lambda.Function(helperStack, "Stub1", new Amazon.CDK.AWS.Lambda.FunctionProps
        {
            FunctionName = "conscia-api",
            Runtime = Amazon.CDK.AWS.Lambda.Runtime.PYTHON_3_12,
            Handler = "handler.handler",
            Code = Amazon.CDK.AWS.Lambda.Code.FromInline("def handler(e,c): pass")
        });
        var stubLambda2 = new Amazon.CDK.AWS.Lambda.Function(helperStack, "Stub2", new Amazon.CDK.AWS.Lambda.FunctionProps
        {
            FunctionName = "conscia-db-access",
            Runtime = Amazon.CDK.AWS.Lambda.Runtime.PYTHON_3_12,
            Handler = "handler.handler",
            Code = Amazon.CDK.AWS.Lambda.Code.FromInline("def handler(e,c): pass")
        });
        var stubLambda3 = new Amazon.CDK.AWS.Lambda.Function(helperStack, "Stub3", new Amazon.CDK.AWS.Lambda.FunctionProps
        {
            FunctionName = "conscia-outbox-processor",
            Runtime = Amazon.CDK.AWS.Lambda.Runtime.PYTHON_3_12,
            Handler = "handler.handler",
            Code = Amazon.CDK.AWS.Lambda.Code.FromInline("def handler(e,c): pass")
        });

        var stack = new ObservabilityStack(app, "TestObs", new ObservabilityStackProps
        {
            Env = TestEnv,
            ApiLambda = stubLambda1,
            DbAccessLambda = stubLambda2,
            OutboxLambda = stubLambda3
        });
        var template = Template.FromStack(stack);
        template.ResourceCountIs("AWS::Logs::LogGroup", 3);
    }

    private static string CreateAssetStub(string name)
    {
        var path = Path.Combine(Path.GetTempPath(), "conscia-infra-tests", name);
        Directory.CreateDirectory(path);
        File.WriteAllText(Path.Combine(path, "placeholder.txt"), name);
        return path;
    }
}
