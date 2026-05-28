using Amazon.CDK;
using Amazon.CDK.AWS.APIGateway;
using Amazon.CDK.AWS.CertificateManager;
using Amazon.CDK.AWS.Cognito;
using Amazon.CDK.AWS.DynamoDB;
using Amazon.CDK.AWS.IAM;
using Amazon.CDK.AWS.Lambda;
using Amazon.CDK.AWS.Route53;
using Amazon.CDK.AWS.S3;
using Amazon.CDK.AWS.SecretsManager;
using Amazon.CDK.AWS.SQS;
using Constructs;

namespace Conscia.Infra;

public class ComputeStackProps : StackProps
{
    public required IBucket ReceiptBucket { get; set; }
    public required IUserPool UserPool { get; set; }
    public required IUserPoolClient UserPoolClient { get; set; }
    public required ITable ControlPlaneTable { get; set; }
    public required ITable TransactionsTable { get; set; }
    public required ITable RecurringSchedulesTable { get; set; }
    public required ITable AiInteractionsTable { get; set; }
    public required ITable OutboxEventsTable { get; set; }
    public required ITable InAppAlertsTable { get; set; }
    public required ITable WeeklyInsightsTable { get; set; }
    public required ITable PurchasePatternsTable { get; set; }
    public required ITable MonthlyCategorySpendsTable { get; set; }
    public required ITable PushDeviceTokensTable { get; set; }
    public required ITable ConscienceJourneyTable { get; set; }
    public required IQueue AiQueue { get; set; }
    public required ProductionRuntimeSettings RuntimeSettings { get; set; }
    public required RuntimeSecretSettings RuntimeSecretSettings { get; set; }
    public string? ApiAssetPath { get; set; }
    public DomainSettings? DomainSettings { get; set; }
}

public class ComputeStack : Stack
{
    public IFunction ApiLambda { get; }
    public LambdaRestApi Api { get; }

    public ComputeStack(Construct scope, string id, ComputeStackProps props)
        : base(scope, id, props)
    {
        var apiAssetPath = props.ApiAssetPath
            ?? AssetPathResolver.ResolvePublishedAsset("../publish/api", "api");

        ApiLambda = new Function(this, "ApiLambda", new FunctionProps
        {
            FunctionName = "conscia-api",
            Runtime = Runtime.DOTNET_8,
            Handler = "Conscia.Api",
            Code = Code.FromAsset(apiAssetPath),
            MemorySize = 1024,
            Timeout = Duration.Seconds(30),
            Architecture = Architecture.ARM_64,
            Environment = new Dictionary<string, string>
            {
                ["ASPNETCORE_ENVIRONMENT"] = "Production",
                ["Auth__Cognito__UserPoolId"] = props.UserPool.UserPoolId,
                ["Auth__Cognito__ClientId"] = props.UserPoolClient.UserPoolClientId,
                ["Auth__Google__ClientId"] = props.RuntimeSettings.AuthGoogleClientId ?? string.Empty,
                ["Auth__Apple__ClientId"] = props.RuntimeSettings.AuthAppleClientId ?? string.Empty,
                ["Apple__KeyId"] = props.RuntimeSettings.AppleKeyId ?? string.Empty,
                ["Apple__IssuerId"] = props.RuntimeSettings.AppleIssuerId ?? string.Empty,
                ["Apple__BundleId"] = props.RuntimeSettings.AppleBundleId ?? string.Empty,
                ["Apple__PrivateKeySecretId"] = props.RuntimeSecretSettings.ApplePrivateKeySecretName,
                ["GooglePlay__PackageName"] = props.RuntimeSettings.GooglePlayPackageName ?? string.Empty,
                ["GooglePlay__ServiceAccountJsonSecretId"] = props.RuntimeSecretSettings.GooglePlayServiceAccountJsonSecretName,
                ["Firebase__AdminServiceAccountJsonSecretId"] = props.RuntimeSecretSettings.FirebaseAdminServiceAccountJsonSecretName,
                ["Firebase__ProjectId"] = props.RuntimeSettings.FirebaseProjectId ?? string.Empty,
                ["InviteEmail__FromEmail"] = props.RuntimeSettings.InviteEmailFromEmail ?? string.Empty,
                ["InviteEmail__ConfigurationSetName"] = props.RuntimeSettings.InviteEmailConfigurationSetName ?? string.Empty,
                ["InviteEmail__DeepLinkBaseUri"] = props.RuntimeSettings.InviteEmailDeepLinkBaseUri,
                ["AWS__S3__BucketName"] = props.ReceiptBucket.BucketName,
                ["AWS__SQS__AiQueueUrl"] = props.AiQueue.QueueUrl,
                ["AWS__DynamoDB__ControlPlaneTable"] = props.ControlPlaneTable.TableName,
                ["AWS__DynamoDB__TransactionsTable"] = props.TransactionsTable.TableName,
                ["AWS__DynamoDB__RecurringSchedulesTable"] = props.RecurringSchedulesTable.TableName,
                ["AWS__DynamoDB__AiInteractionsTable"] = props.AiInteractionsTable.TableName,
                ["AWS__DynamoDB__OutboxEventsTable"] = props.OutboxEventsTable.TableName,
                ["AWS__DynamoDB__InAppAlertsTable"] = props.InAppAlertsTable.TableName,
                ["AWS__DynamoDB__WeeklyInsightsTable"] = props.WeeklyInsightsTable.TableName,
                ["AWS__DynamoDB__PurchasePatternsTable"] = props.PurchasePatternsTable.TableName,
                ["AWS__DynamoDB__MonthlyCategorySpendsTable"] = props.MonthlyCategorySpendsTable.TableName,
                ["AWS__DynamoDB__PushDeviceTokensTable"] = props.PushDeviceTokensTable.TableName,
                ["AWS__DynamoDB__ConscienceJourneyTable"] = props.ConscienceJourneyTable.TableName
            },
            Tracing = Tracing.ACTIVE
        });

        Api = new LambdaRestApi(this, "ConsciaApi", new LambdaRestApiProps
        {
            Handler = ApiLambda,
            RestApiName = "conscia-api",
            Proxy = true,
            DeployOptions = new StageOptions
            {
                StageName = "api",
                TracingEnabled = true,
                ThrottlingRateLimit = 100,
                ThrottlingBurstLimit = 200,
                MethodOptions = new Dictionary<string, IMethodDeploymentOptions>
                {
                    ["/api/ai/pre-purchase/POST"] = new MethodDeploymentOptions
                    {
                        ThrottlingRateLimit = 10,
                        ThrottlingBurstLimit = 20
                    },
                    ["/api/ai/reflection/POST"] = new MethodDeploymentOptions
                    {
                        ThrottlingRateLimit = 10,
                        ThrottlingBurstLimit = 20
                    },
                    ["/api/receipts/scan/POST"] = new MethodDeploymentOptions
                    {
                        ThrottlingRateLimit = 5,
                        ThrottlingBurstLimit = 10
                    }
                }
            },
            DefaultCorsPreflightOptions = new CorsOptions
            {
                AllowOrigins = props.DomainSettings?.AllowedCorsOrigins ?? Cors.ALL_ORIGINS,
                AllowMethods = Cors.ALL_METHODS,
                AllowHeaders = ["Authorization", "Content-Type"],
                MaxAge = Duration.Hours(1)
            }
        });

        if (props.DomainSettings is not null)
        {
            ConfigureCustomApiDomain(props.DomainSettings);
        }

        props.ControlPlaneTable.GrantReadWriteData(ApiLambda);
        props.TransactionsTable.GrantReadWriteData(ApiLambda);
        props.RecurringSchedulesTable.GrantReadWriteData(ApiLambda);
        props.AiInteractionsTable.GrantReadWriteData(ApiLambda);
        props.OutboxEventsTable.GrantReadWriteData(ApiLambda);
        props.InAppAlertsTable.GrantReadWriteData(ApiLambda);
        props.WeeklyInsightsTable.GrantReadWriteData(ApiLambda);
        props.PurchasePatternsTable.GrantReadWriteData(ApiLambda);
        props.MonthlyCategorySpendsTable.GrantReadWriteData(ApiLambda);
        props.PushDeviceTokensTable.GrantReadWriteData(ApiLambda);
        props.ConscienceJourneyTable.GrantReadWriteData(ApiLambda);
        props.ReceiptBucket.GrantReadWrite(ApiLambda);
        props.AiQueue.GrantSendMessages(ApiLambda);
        GrantRuntimeSecretReads(props.RuntimeSecretSettings);

        ApiLambda.AddToRolePolicy(new PolicyStatement(new PolicyStatementProps
        {
            Actions = ["bedrock:InvokeModel"],
            Resources = [$"arn:aws:bedrock:{Region}::foundation-model/anthropic.*"]
        }));

        ApiLambda.AddToRolePolicy(new PolicyStatement(new PolicyStatementProps
        {
            Actions = ["textract:DetectDocumentText"],
            Resources = ["*"]
        }));

        new CfnOutput(this, "ApiUrl", new CfnOutputProps { Value = Api.Url });
        new CfnOutput(this, "ApiEndpoint", new CfnOutputProps { Value = Api.Url });
    }

    private void GrantRuntimeSecretReads(RuntimeSecretSettings runtimeSecretSettings)
    {
        Secret.FromSecretNameV2(this, "ApplePrivateKeySecret", runtimeSecretSettings.ApplePrivateKeySecretName)
            .GrantRead(ApiLambda);
        Secret.FromSecretNameV2(this, "GooglePlayServiceAccountJsonSecret", runtimeSecretSettings.GooglePlayServiceAccountJsonSecretName)
            .GrantRead(ApiLambda);
        Secret.FromSecretNameV2(this, "FirebaseAdminServiceAccountJsonSecret", runtimeSecretSettings.FirebaseAdminServiceAccountJsonSecretName)
            .GrantRead(ApiLambda);
    }

    private void ConfigureCustomApiDomain(DomainSettings domainSettings)
    {
        var hostedZone = HostedZone.FromHostedZoneAttributes(this, "HostedZone", new HostedZoneAttributes
        {
            HostedZoneId = domainSettings.HostedZoneId,
            ZoneName = domainSettings.RootDomainName
        });

        var certificate = new Certificate(this, "ApiCertificate", new CertificateProps
        {
            DomainName = domainSettings.ApiDomainName,
            Validation = CertificateValidation.FromDns(hostedZone)
        });

        var domainName = new CfnDomainName(this, "ApiDomainName", new CfnDomainNameProps
        {
            DomainName = domainSettings.ApiDomainName,
            RegionalCertificateArn = certificate.CertificateArn,
            EndpointConfiguration = new CfnDomainName.EndpointConfigurationProperty
            {
                Types = ["REGIONAL"]
            },
            SecurityPolicy = "TLS_1_2"
        });

        new CfnBasePathMapping(this, "ApiBasePathMapping", new CfnBasePathMappingProps
        {
            DomainName = domainName.Ref,
            RestApiId = Api.RestApiId,
            Stage = Api.DeploymentStage.StageName
        });

        new CfnRecordSet(this, "ApiAliasRecord", new CfnRecordSetProps
        {
            HostedZoneId = domainSettings.HostedZoneId,
            Name = $"{domainSettings.ApiDomainName}.",
            Type = "A",
            AliasTarget = new CfnRecordSet.AliasTargetProperty
            {
                DnsName = domainName.AttrRegionalDomainName,
                HostedZoneId = domainName.AttrRegionalHostedZoneId,
                EvaluateTargetHealth = false
            }
        });

        new CfnOutput(this, "CustomApiUrl", new CfnOutputProps
        {
            Value = $"https://{domainSettings.ApiDomainName}/"
        });
    }
}
