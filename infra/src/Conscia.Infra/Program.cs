using Amazon.CDK;

namespace Conscia.Infra;

sealed class Program
{
    public static void Main(string[] args)
    {
        var app = new App();

        var env = new Amazon.CDK.Environment
        {
            Account = System.Environment.GetEnvironmentVariable("CDK_DEFAULT_ACCOUNT"),
            Region = System.Environment.GetEnvironmentVariable("CDK_DEFAULT_REGION") ?? "us-east-1"
        };

        var network = new NetworkStack(app, "Conscia-Network", new StackProps { Env = env });

        var database = new DatabaseStack(app, "Conscia-Database", new DatabaseStackProps
        {
            Env = env,
            Vpc = network.Vpc,
            DbSecurityGroup = network.DbSecurityGroup
        });

        var storage = new StorageStack(app, "Conscia-Storage", new StackProps { Env = env });
        var auth = new AuthStack(app, "Conscia-Auth", new StackProps { Env = env });

        var ai = new AIStack(app, "Conscia-AI", new StackProps { Env = env });

        var dbAccess = new DbAccessStack(app, "Conscia-DbAccess", new DbAccessStackProps
        {
            Env = env,
            Vpc = network.Vpc,
            DbSecurityGroup = network.DbSecurityGroup,
            DbInstance = database.DbInstance,
            DbPasswordSecret = database.DbPasswordSecret
        });

        var compute = new ComputeStack(app, "Conscia-Compute", new ComputeStackProps
        {
            Env = env,
            ReceiptBucket = storage.ReceiptBucket,
            UserPool = auth.UserPool,
            UserPoolClient = auth.UserPoolClient,
            TransactionsTable = database.TransactionsTable,
            AiInteractionsTable = database.AiInteractionsTable,
            OutboxEventsTable = database.OutboxEventsTable,
            InAppAlertsTable = database.InAppAlertsTable,
            WeeklyInsightsTable = database.WeeklyInsightsTable,
            PurchasePatternsTable = database.PurchasePatternsTable,
            AiQueue = ai.AiQueue,
            DbAccessLambda = dbAccess.DbAccessLambda
        });

        var outbox = new OutboxStack(app, "Conscia-Outbox", new OutboxStackProps
        {
            Env = env,
            TransactionsTable = database.TransactionsTable,
            OutboxEventsTable = database.OutboxEventsTable,
            DbPasswordSecret = database.DbPasswordSecret,
            Vpc = network.Vpc,
            DbSecurityGroup = network.DbSecurityGroup,
            DbInstance = database.DbInstance
        });

        _ = new ObservabilityStack(app, "Conscia-Observability", new ObservabilityStackProps
        {
            Env = env,
            ApiLambda = compute.ApiLambda,
            DbAccessLambda = dbAccess.DbAccessLambda,
            OutboxLambda = outbox.OutboxLambda
        });

        _ = new PatternAggregatorStack(app, "Conscia-PatternAggregator", new PatternAggregatorStackProps
        {
            Env = env,
            TransactionsTable = database.TransactionsTable,
            WeeklyInsightsTable = database.WeeklyInsightsTable,
            PurchasePatternsTable = database.PurchasePatternsTable
        });

        var web = new WebStack(app, "Conscia-Web", new StackProps { Env = env });

        var cicd = new CiCdStack(app, "Conscia-CiCd", new CiCdStackProps
        {
            Env = env,
            GitHubOrg = "your-org",
            GitHubRepo = "conscia"
        });

        app.Synth();
    }
}
