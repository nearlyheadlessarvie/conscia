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
            Region = System.Environment.GetEnvironmentVariable("CDK_DEFAULT_REGION") ?? "ap-southeast-1"
        };
        var domainSettings = DomainSettings.FromEnvironment();
        var managedLoginProviderSettings = ManagedLoginProviderSettings.FromEnvironment();
        var runtimeSettings = ProductionRuntimeSettings.FromEnvironment();
        var runtimeSecretSettings = RuntimeSecretSettings.FromEnvironment();

        var database = new DatabaseStack(app, "Conscia-Database", new StackProps { Env = env });

        var storage = new StorageStack(app, "Conscia-Storage", new StorageStackProps
        {
            Env = env,
            AllowedCorsOrigins = domainSettings?.AllowedCorsOrigins ?? ["*"]
        });
        var auth = new AuthStack(app, "Conscia-Auth", new AuthStackProps
        {
            Env = env,
            CognitoPreSignupLinkerAssetPath = AssetPathResolver.ResolvePublishedAsset(
                "../publish/cognito-pre-signup-linker",
                "cognito-pre-signup-linker"),
            DomainSettings = domainSettings,
            ManagedLoginProviderSettings = managedLoginProviderSettings
        });

        var ai = new AIStack(app, "Conscia-AI", new StackProps { Env = env });

        var compute = new ComputeStack(app, "Conscia-Compute", new ComputeStackProps
        {
            Env = env,
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
            RuntimeSettings = runtimeSettings,
            RuntimeSecretSettings = runtimeSecretSettings,
            DomainSettings = domainSettings
        });

        var outbox = new OutboxStack(app, "Conscia-Outbox", new OutboxStackProps
        {
            Env = env,
            ControlPlaneTable = database.ControlPlaneTable,
            TransactionsTable = database.TransactionsTable,
            OutboxEventsTable = database.OutboxEventsTable,
            InAppAlertsTable = database.InAppAlertsTable,
            MonthlyCategorySpendsTable = database.MonthlyCategorySpendsTable,
            PushDeviceTokensTable = database.PushDeviceTokensTable,
            RuntimeSettings = runtimeSettings,
            RuntimeSecretSettings = runtimeSecretSettings,
            DomainSettings = domainSettings
        });

        var recurring = new RecurringProcessorStack(app, "Conscia-RecurringProcessor", new RecurringProcessorStackProps
        {
            Env = env,
            TransactionsTable = database.TransactionsTable,
            RecurringSchedulesTable = database.RecurringSchedulesTable,
            OutboxEventsTable = database.OutboxEventsTable,
            InAppAlertsTable = database.InAppAlertsTable
        });

        _ = new ObservabilityStack(app, "Conscia-Observability", new ObservabilityStackProps
        {
            Env = env,
            ApiLambda = compute.ApiLambda,
            OutboxLambda = outbox.OutboxLambda,
            RecurringProcessorLambda = recurring.RecurringProcessorLambda
        });

        _ = new PatternAggregatorStack(app, "Conscia-PatternAggregator", new PatternAggregatorStackProps
        {
            Env = env,
            ControlPlaneTable = database.ControlPlaneTable,
            TransactionsTable = database.TransactionsTable,
            WeeklyInsightsTable = database.WeeklyInsightsTable,
            PurchasePatternsTable = database.PurchasePatternsTable,
            MonthlyCategorySpendsTable = database.MonthlyCategorySpendsTable
        });

        _ = new EmailStack(app, "Conscia-Email", new EmailStackProps
        {
            Env = env,
            DomainSettings = domainSettings
        });

        _ = new WebStack(app, "Conscia-Web", new WebStackProps
        {
            Env = env,
            DomainSettings = domainSettings
        });

        _ = new CiCdStack(app, "Conscia-CiCd", new CiCdStackProps
        {
            Env = env,
            GitHubOrg = "nearlyheadlessarvie",
            GitHubRepo = "conscia"
        });

        app.Synth();
    }
}
