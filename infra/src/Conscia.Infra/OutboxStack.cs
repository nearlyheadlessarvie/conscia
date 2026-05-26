using Amazon.CDK;
using Amazon.CDK.AWS.DynamoDB;
using Amazon.CDK.AWS.IAM;
using Amazon.CDK.AWS.Lambda;
using Amazon.CDK.AWS.Lambda.EventSources;
using Amazon.CDK.AWS.SecretsManager;
using Constructs;

namespace Conscia.Infra;

public class OutboxStackProps : StackProps
{
    public required ITable ControlPlaneTable { get; set; }
    public required ITable TransactionsTable { get; set; }
    public required ITable OutboxEventsTable { get; set; }
    public required ITable InAppAlertsTable { get; set; }
    public required ITable MonthlyCategorySpendsTable { get; set; }
    public required ITable PushDeviceTokensTable { get; set; }
    public required ProductionRuntimeSettings RuntimeSettings { get; set; }
    public required RuntimeSecretSettings RuntimeSecretSettings { get; set; }
    public string? AssetPath { get; set; }
    public DomainSettings? DomainSettings { get; set; }
}

public class OutboxStack : Stack
{
    public IFunction OutboxLambda { get; }

    public OutboxStack(Construct scope, string id, OutboxStackProps props)
        : base(scope, id, props)
    {
        var assetPath = props.AssetPath
            ?? AssetPathResolver.ResolvePublishedAsset("../publish/outbox", "outbox");

        OutboxLambda = new Function(this, "OutboxLambda", new FunctionProps
        {
            FunctionName = "conscia-outbox-processor",
            Runtime = Runtime.DOTNET_8,
            Handler = "Conscia.OutboxProcessor",
            Code = Code.FromAsset(assetPath),
            MemorySize = 512,
            Timeout = Duration.Seconds(60),
            Architecture = Architecture.ARM_64,
            Environment = new Dictionary<string, string>
            {
                ["AWS__DynamoDB__ControlPlaneTable"] = props.ControlPlaneTable.TableName,
                ["AWS__DynamoDB__TransactionsTable"] = props.TransactionsTable.TableName,
                ["AWS__DynamoDB__OutboxEventsTable"] = props.OutboxEventsTable.TableName,
                ["AWS__DynamoDB__InAppAlertsTable"] = props.InAppAlertsTable.TableName,
                ["AWS__DynamoDB__MonthlyCategorySpendsTable"] = props.MonthlyCategorySpendsTable.TableName,
                ["AWS__DynamoDB__PushDeviceTokensTable"] = props.PushDeviceTokensTable.TableName,
                ["Firebase__AdminServiceAccountJsonSecretId"] = props.RuntimeSecretSettings.FirebaseAdminServiceAccountJsonSecretName,
                ["Firebase__ProjectId"] = props.RuntimeSettings.FirebaseProjectId ?? string.Empty,
                ["InviteEmail__FromEmail"] = props.RuntimeSettings.InviteEmailFromEmail
                    ?? (props.DomainSettings is null ? string.Empty : $"invites@{props.DomainSettings.RootDomainName}"),
                ["InviteEmail__ConfigurationSetName"] = props.RuntimeSettings.InviteEmailConfigurationSetName
                    ?? (props.DomainSettings is null ? string.Empty : "conscia-production"),
                ["InviteEmail__DeepLinkBaseUri"] = props.RuntimeSettings.InviteEmailDeepLinkBaseUri,
                ["SES_FROM_EMAIL"] = props.RuntimeSettings.InviteEmailFromEmail
                    ?? (props.DomainSettings is null ? string.Empty : $"invites@{props.DomainSettings.RootDomainName}"),
                ["SES_CONFIGURATION_SET"] = props.RuntimeSettings.InviteEmailConfigurationSetName
                    ?? (props.DomainSettings is null ? string.Empty : "conscia-production")
            },
            Tracing = Tracing.ACTIVE
        });

        OutboxLambda.AddEventSource(new DynamoEventSource(props.TransactionsTable, new DynamoEventSourceProps
        {
            StartingPosition = StartingPosition.TRIM_HORIZON,
            BatchSize = 10,
            MaxBatchingWindow = Duration.Seconds(5),
            RetryAttempts = 3,
            BisectBatchOnError = true
        }));

        props.ControlPlaneTable.GrantReadWriteData(OutboxLambda);
        props.TransactionsTable.GrantReadWriteData(OutboxLambda);
        props.OutboxEventsTable.GrantReadWriteData(OutboxLambda);
        props.InAppAlertsTable.GrantReadWriteData(OutboxLambda);
        props.MonthlyCategorySpendsTable.GrantReadWriteData(OutboxLambda);
        props.PushDeviceTokensTable.GrantReadData(OutboxLambda);
        Secret.FromSecretNameV2(this, "FirebaseAdminServiceAccountJsonSecret", props.RuntimeSecretSettings.FirebaseAdminServiceAccountJsonSecretName)
            .GrantRead(OutboxLambda);

        if (props.DomainSettings is not null)
        {
            OutboxLambda.AddToRolePolicy(new PolicyStatement(new PolicyStatementProps
            {
                Actions = ["ses:SendEmail", "ses:SendRawEmail"],
                Resources =
                [
                    $"arn:aws:ses:{Region}:{Account}:identity/{props.DomainSettings.RootDomainName}"
                ]
            }));
        }
    }
}
