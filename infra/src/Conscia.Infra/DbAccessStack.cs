using Amazon.CDK;
using Amazon.CDK.AWS.EC2;
using Amazon.CDK.AWS.Lambda;
using Amazon.CDK.AWS.RDS;
using Amazon.CDK.AWS.SecretsManager;
using Constructs;

namespace Conscia.Infra;

public class DbAccessStackProps : StackProps
{
    public required IVpc Vpc { get; set; }
    public required ISecurityGroup DbSecurityGroup { get; set; }
    public required IDatabaseInstance DbInstance { get; set; }
    public required ISecret DbPasswordSecret { get; set; }
    public string AssetPath { get; set; } = "../publish/db-access";
}

public class DbAccessStack : Stack
{
    public IFunction DbAccessLambda { get; }

    public DbAccessStack(Construct scope, string id, DbAccessStackProps props)
        : base(scope, id, props)
    {
        var lambdaSg = new SecurityGroup(this, "DbAccessLambdaSg", new SecurityGroupProps
        {
            Vpc = props.Vpc,
            Description = "Security group for DB access Lambda"
        });

        props.DbSecurityGroup.AddIngressRule(
            lambdaSg,
            Port.Tcp(5432),
            "Allow Lambda to connect to RDS PostgreSQL");

        DbAccessLambda = new Function(this, "DbAccessLambda", new FunctionProps
        {
            FunctionName = "conscia-db-access",
            Runtime = Runtime.DOTNET_8,
            Handler = "Conscia.DbAccess",
            Code = Code.FromAsset(props.AssetPath),
            MemorySize = 512,
            Timeout = Duration.Seconds(30),
            Architecture = Architecture.ARM_64,
            Vpc = props.Vpc,
            VpcSubnets = new SubnetSelection { SubnetType = SubnetType.PRIVATE_ISOLATED },
            SecurityGroups = [lambdaSg],
            Environment = new Dictionary<string, string>
            {
                ["DB_HOST"] = props.DbInstance.InstanceEndpoint.Hostname,
                ["DB_PORT"] = "5432",
                ["DB_NAME"] = InfraConstants.DatabaseName,
                ["DB_USERNAME"] = InfraConstants.DatabaseUsername,
                ["DB_PASSWORD"] = props.DbPasswordSecret.SecretValue.UnsafeUnwrap()
            },
            Tracing = Tracing.ACTIVE
        });
    }
}
