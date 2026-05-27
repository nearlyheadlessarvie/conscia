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
        var stack = new AuthStack(app, "TestAuth", new AuthStackProps
        {
            Env = TestEnv,
            DomainSettings = TestDomainSettings
        });
        var template = Template.FromStack(stack);

        template.ResourceCountIs("AWS::Cognito::UserPool", 1);
        template.ResourceCountIs("AWS::Cognito::UserPoolClient", 1);
        template.HasResourceProperties("AWS::Cognito::UserPool", new Dictionary<string, object>
        {
            ["UserPoolName"] = "conscia-users",
            ["UserPoolTier"] = "ESSENTIALS",
            ["WebAuthnRelyingPartyID"] = "getconscia.com",
            ["WebAuthnUserVerification"] = "preferred",
            ["EmailConfiguration"] = Match.ObjectLike(new Dictionary<string, object>
            {
                ["EmailSendingAccount"] = "DEVELOPER",
                ["From"] = "no-reply@getconscia.com",
                ["SourceArn"] = Match.AnyValue()
            }),
            ["Policies"] = Match.ObjectLike(new Dictionary<string, object>
            {
                ["SignInPolicy"] = Match.ObjectLike(new Dictionary<string, object>
                {
                    ["AllowedFirstAuthFactors"] = Match.ArrayWith(["PASSWORD", "WEB_AUTHN"])
                })
            })
        });
        template.HasResourceProperties("AWS::Cognito::UserPoolClient", new Dictionary<string, object>
        {
            ["ExplicitAuthFlows"] = Match.ArrayWith([
                "ALLOW_USER_PASSWORD_AUTH",
                "ALLOW_USER_SRP_AUTH",
                "ALLOW_REFRESH_TOKEN_AUTH",
                "ALLOW_USER_AUTH"
            ])
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
            RuntimeSettings = new ProductionRuntimeSettings(
                "jwt-signing-key",
                "google-client-id",
                "com.getconscia.app.ai",
                "APPLEKEYID",
                "00000000-0000-0000-0000-000000000000",
                "com.getconscia.app.ai",
                "private-key",
                "com.getconscia.app.ai",
                "service-account-json",
                "firebase-service-account",
                "conscia-prod",
                "invites@getconscia.com",
                "conscia-production",
                "conscia://invite",
                "1.2.3",
                "abc123def456",
                "2026-05-27T12:34:56Z"),
            RuntimeSecretSettings = new RuntimeSecretSettings(
                "test/auth-app-jwt-signing-key",
                "test/apple-private-key",
                "test/google-play-service-account-json",
                "test/firebase-admin-service-account-json"),
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
                    ["AWS__DynamoDB__TransactionsTable"] = Match.AnyValue(),
                    ["Firebase__AdminServiceAccountJsonSecretId"] = "test/firebase-admin-service-account-json",
                    ["GooglePlay__ServiceAccountJsonSecretId"] = "test/google-play-service-account-json",
                    ["InviteEmail__FromEmail"] = "invites@getconscia.com",
                    ["Version__Release"] = "1.2.3",
                    ["Version__CommitSha"] = "abc123def456",
                    ["Version__DeployedAt"] = "2026-05-27T12:34:56Z"
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
            PushDeviceTokensTable = database.PushDeviceTokensTable,
            RuntimeSettings = new ProductionRuntimeSettings(
                "jwt-signing-key",
                "google-client-id",
                "com.getconscia.app.ai",
                "APPLEKEYID",
                "00000000-0000-0000-0000-000000000000",
                "com.getconscia.app.ai",
                "private-key",
                "com.getconscia.app.ai",
                "service-account-json",
                "firebase-service-account",
                "conscia-prod",
                "invites@getconscia.com",
                "conscia-production",
                "conscia://invite",
                "1.2.3",
                "abc123def456",
                "2026-05-27T12:34:56Z"),
            RuntimeSecretSettings = new RuntimeSecretSettings(
                "test/auth-app-jwt-signing-key",
                "test/apple-private-key",
                "test/google-play-service-account-json",
                "test/firebase-admin-service-account-json"),
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
        template.HasResourceProperties("AWS::Lambda::Function", new Dictionary<string, object>
        {
            ["Environment"] = new Dictionary<string, object>
            {
                ["Variables"] = Match.ObjectLike(new Dictionary<string, object>
                {
                    ["AWS__DynamoDB__PushDeviceTokensTable"] = Match.AnyValue(),
                    ["Firebase__AdminServiceAccountJsonSecretId"] = "test/firebase-admin-service-account-json",
                    ["InviteEmail__FromEmail"] = "invites@getconscia.com"
                })
            }
        });
    }

    [Fact]
    public void RecurringProcessorStack_CreatesScheduledLambda()
    {
        var app = new App();
        var database = new DatabaseStack(app, "D", new StackProps { Env = TestEnv });
        var stack = new RecurringProcessorStack(app, "R", new RecurringProcessorStackProps
        {
            Env = TestEnv,
            TransactionsTable = database.TransactionsTable,
            RecurringSchedulesTable = database.RecurringSchedulesTable,
            OutboxEventsTable = database.OutboxEventsTable,
            InAppAlertsTable = database.InAppAlertsTable,
            AssetPath = CreateAssetStub("recurring-processor")
        });

        Assert.NotNull(stack.RecurringProcessorLambda);

        var template = Template.FromStack(stack);
        template.ResourceCountIs("AWS::Lambda::Function", 1);
        template.ResourceCountIs("AWS::Events::Rule", 1);
        template.HasResourceProperties("AWS::Lambda::Function", new Dictionary<string, object>
        {
            ["FunctionName"] = "conscia-recurring-processor",
            ["Environment"] = new Dictionary<string, object>
            {
                ["Variables"] = Match.ObjectLike(new Dictionary<string, object>
                {
                    ["AWS__DynamoDB__TransactionsTable"] = Match.AnyValue(),
                    ["AWS__DynamoDB__RecurringSchedulesTable"] = Match.AnyValue(),
                    ["AWS__DynamoDB__OutboxEventsTable"] = Match.AnyValue(),
                    ["AWS__DynamoDB__InAppAlertsTable"] = Match.AnyValue()
                })
            }
        });
        template.HasResourceProperties("AWS::Events::Rule", new Dictionary<string, object>
        {
            ["ScheduleExpression"] = "rate(5 minutes)"
        });
    }

    [Fact]
    public void AssetPathResolver_Throws_WhenPublishAssetIsMissing_AndFallbackNotEnabled()
    {
        var originalDirectory = Directory.GetCurrentDirectory();
        var originalFallback = System.Environment.GetEnvironmentVariable("CONSCIA_ALLOW_PLACEHOLDER_ASSETS");
        var tempRoot = Path.Combine(Path.GetTempPath(), "conscia-infra-tests", Guid.NewGuid().ToString("N"));
        var infraRoot = Path.Combine(tempRoot, "infra");
        Directory.CreateDirectory(Path.Combine(infraRoot, "src", "Conscia.Infra"));
        File.WriteAllText(
            Path.Combine(infraRoot, "src", "Conscia.Infra", "Conscia.Infra.csproj"),
            "<Project Sdk=\"Microsoft.NET.Sdk\"></Project>");

        try
        {
            System.Environment.SetEnvironmentVariable("CONSCIA_ALLOW_PLACEHOLDER_ASSETS", null);
            Directory.SetCurrentDirectory(infraRoot);

            var ex = Assert.Throws<InvalidOperationException>(() =>
                AssetPathResolver.ResolvePublishedAsset("../publish/api", "api"));

            Assert.Contains("Publish release binaries before deploying runtime stacks.", ex.Message);
        }
        finally
        {
            Directory.SetCurrentDirectory(originalDirectory);
            System.Environment.SetEnvironmentVariable("CONSCIA_ALLOW_PLACEHOLDER_ASSETS", originalFallback);
            if (Directory.Exists(tempRoot))
            {
                Directory.Delete(tempRoot, true);
            }
        }
    }

    [Fact]
    public void AssetPathResolver_FallsBackToPlaceholder_WhenPublishAssetIsMissing_AndFallbackEnabled()
    {
        var originalDirectory = Directory.GetCurrentDirectory();
        var originalFallback = System.Environment.GetEnvironmentVariable("CONSCIA_ALLOW_PLACEHOLDER_ASSETS");
        var tempRoot = Path.Combine(Path.GetTempPath(), "conscia-infra-tests", Guid.NewGuid().ToString("N"));
        var infraRoot = Path.Combine(tempRoot, "infra");
        Directory.CreateDirectory(Path.Combine(infraRoot, "src", "Conscia.Infra"));
        File.WriteAllText(
            Path.Combine(infraRoot, "src", "Conscia.Infra", "Conscia.Infra.csproj"),
            "<Project Sdk=\"Microsoft.NET.Sdk\"></Project>");

        try
        {
            System.Environment.SetEnvironmentVariable("CONSCIA_ALLOW_PLACEHOLDER_ASSETS", "true");
            Directory.SetCurrentDirectory(infraRoot);

            var resolved = AssetPathResolver.ResolvePublishedAsset("../publish/api", "api");

            Assert.True(Directory.Exists(resolved));
            Assert.EndsWith(Path.Combine(".asset-placeholders", "api"), resolved);
            Assert.True(File.Exists(Path.Combine(resolved, "placeholder.txt")));
        }
        finally
        {
            Directory.SetCurrentDirectory(originalDirectory);
            System.Environment.SetEnvironmentVariable("CONSCIA_ALLOW_PLACEHOLDER_ASSETS", originalFallback);
            if (Directory.Exists(tempRoot))
            {
                Directory.Delete(tempRoot, true);
            }
        }
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
        template.ResourceCountIs("AWS::CloudFront::Function", 1);
        template.HasResourceProperties("AWS::CloudFront::Distribution", new Dictionary<string, object>
        {
            ["DistributionConfig"] = new Dictionary<string, object>
            {
                ["Aliases"] = Match.ArrayWith(TestDomainSettings.WebDomainNames),
                ["DefaultCacheBehavior"] = Match.ObjectLike(new Dictionary<string, object>
                {
                    ["FunctionAssociations"] = Match.ArrayWith([
                        Match.ObjectLike(new Dictionary<string, object>
                        {
                            ["EventType"] = "viewer-request"
                        })
                    ])
                })
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
            DomainSettings = TestDomainSettings with
            {
                IcloudInboxMxRecords =
                [
                    new DnsMxRecord(10, "mx01.mail.icloud.com"),
                    new DnsMxRecord(10, "mx02.mail.icloud.com")
                ],
                IcloudInboxTxtRecords =
                [
                    new DnsTxtRecord("@", "v=spf1 include:icloud.com ~all"),
                    new DnsTxtRecord("@", "apple-domain=abc123")
                ],
                IcloudInboxCnameRecords =
                [
                    new DnsCnameRecord("sig1._domainkey", "sig1.dkim.mail.icloud.com"),
                    new DnsCnameRecord("sig2._domainkey", "sig2.dkim.mail.icloud.com")
                ]
            }
        });
        var template = Template.FromStack(stack);

        template.HasResourceProperties("AWS::SES::EmailIdentity", new Dictionary<string, object>
        {
            ["EmailIdentity"] = "getconscia.com",
            ["MailFromAttributes"] = new Dictionary<string, object>
            {
                ["BehaviorOnMxFailure"] = "REJECT_MESSAGE",
                ["MailFromDomain"] = "feedback.getconscia.com"
            }
        });
        template.ResourceCountIs("AWS::SES::ConfigurationSet", 1);
        template.ResourceCountIs("AWS::Route53::RecordSet", 10);
        template.HasResourceProperties("AWS::Route53::RecordSet", new Dictionary<string, object>
        {
            ["Name"] = "feedback.getconscia.com.",
            ["Type"] = "MX",
            ["ResourceRecords"] = new object[] { "10 feedback-smtp.us-east-1.amazonses.com" }
        });
        template.HasResourceProperties("AWS::Route53::RecordSet", new Dictionary<string, object>
        {
            ["Name"] = "feedback.getconscia.com.",
            ["Type"] = "TXT",
            ["ResourceRecords"] = new object[] { "\"v=spf1 include:amazonses.com ~all\"" }
        });
        template.HasResourceProperties("AWS::Route53::RecordSet", new Dictionary<string, object>
        {
            ["Name"] = "getconscia.com.",
            ["Type"] = "MX",
            ["ResourceRecords"] = Match.ArrayWith(new object[]
            {
                "10 mx01.mail.icloud.com",
                "10 mx02.mail.icloud.com"
            })
        });
        template.HasResourceProperties("AWS::Route53::RecordSet", new Dictionary<string, object>
        {
            ["Name"] = "_dmarc.getconscia.com.",
            ["Type"] = "TXT",
            ["ResourceRecords"] = new object[] { "\"v=DMARC1; p=quarantine; adkim=s; aspf=s; pct=100\"" }
        });
        template.HasResourceProperties("AWS::Route53::RecordSet", new Dictionary<string, object>
        {
            ["Name"] = "getconscia.com.",
            ["Type"] = "TXT",
            ["ResourceRecords"] = Match.ArrayWith(new object[]
            {
                "\"v=spf1 include:icloud.com ~all\"",
                "\"apple-domain=abc123\""
            })
        });
    }

    [Fact]
    public void EmailStack_IgnoresIncompleteIcloudCnameRecords()
    {
        var app = new App();
        var stack = new EmailStack(app, "TestEmailInvalidCname", new EmailStackProps
        {
            Env = TestEnv,
            DomainSettings = TestDomainSettings with
            {
                IcloudInboxCnameRecords =
                [
                    new DnsCnameRecord("sig1._domainkey", null!)
                ]
            }
        });
        var template = Template.FromStack(stack);

        template.ResourceCountIs("AWS::Route53::RecordSet", 6);
    }

    [Fact]
    public void ObservabilityStack_ManagesLambdaLogRetention()
    {
        var app = new App();
        var helperStack = new Stack(app, "Helper", new StackProps { Env = TestEnv });

        var api = CreateStubLambda(helperStack, "ApiStub", "conscia-api");
        var outbox = CreateStubLambda(helperStack, "OutboxStub", "conscia-outbox-processor");
        var recurring = CreateStubLambda(helperStack, "RecurringStub", "conscia-recurring-processor");
        var stack = new ObservabilityStack(app, "TestObs", new ObservabilityStackProps
        {
            Env = TestEnv,
            ApiLambda = api,
            OutboxLambda = outbox,
            RecurringProcessorLambda = recurring
        });

        var template = Template.FromStack(stack);
        template.ResourceCountIs("Custom::LogRetention", 3);
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
        var auth = new AuthStack(app, "A", new AuthStackProps
        {
            Env = TestEnv,
            DomainSettings = TestDomainSettings
        });
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
