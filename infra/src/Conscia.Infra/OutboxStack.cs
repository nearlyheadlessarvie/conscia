using Amazon.CDK;
using Amazon.CDK.AWS.DynamoDB;
using Amazon.CDK.AWS.EC2;
using Amazon.CDK.AWS.Lambda;
using Amazon.CDK.AWS.Lambda.EventSources;
using Amazon.CDK.AWS.RDS;
using Amazon.CDK.AWS.SecretsManager;
using Constructs;

namespace Conscia.Infra;

public class OutboxStackProps : StackProps
{
    public required ITable TransactionsTable { get; set; }
    public required ITable OutboxEventsTable { get; set; }
    public required ISecret DbPasswordSecret { get; set; }
    public required IVpc Vpc { get; set; }
    public required ISecurityGroup DbSecurityGroup { get; set; }
    public required IDatabaseInstance DbInstance { get; set; }
}

public class OutboxStack : Stack
{
    public IFunction OutboxLambda { get; }

    public OutboxStack(Construct scope, string id, OutboxStackProps props)
        : base(scope, id, props)
    {
        var lambdaSg = new SecurityGroup(this, "OutboxLambdaSg", new SecurityGroupProps
        {
            Vpc = props.Vpc,
            Description = "Security group for outbox processor Lambda"
        });

        props.DbSecurityGroup.AddIngressRule(
            lambdaSg,
            Port.Tcp(5432),
            "Allow outbox Lambda to connect to RDS");

        OutboxLambda = new Function(this, "OutboxLambda", new FunctionProps
        {
            FunctionName = "conscia-outbox-processor",
            Runtime = Runtime.DOTNET_8,
            Handler = "Conscia.OutboxProcessor",
            Code = Code.FromAsset("../publish/outbox"),
            MemorySize = 512,
            Timeout = Duration.Seconds(60),
            Architecture = Architecture.ARM_64,
            Vpc = props.Vpc,
            VpcSubnets = new SubnetSelection { SubnetType = SubnetType.PRIVATE_ISOLATED },
            SecurityGroups = [lambdaSg],
            Environment = new Dictionary<string, string>
            {
                ["OUTBOX_TABLE"] = props.OutboxEventsTable.TableName,
                ["DB_HOST"] = props.DbInstance.InstanceEndpoint.Hostname,
                ["DB_PORT"] = "5432",
                ["DB_NAME"] = InfraConstants.DatabaseName,
                ["DB_USERNAME"] = InfraConstants.DatabaseUsername,
                ["DB_PASSWORD"] = props.DbPasswordSecret.SecretValue.UnsafeUnwrap()
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

        props.OutboxEventsTable.GrantReadWriteData(OutboxLambda);
    }
}
