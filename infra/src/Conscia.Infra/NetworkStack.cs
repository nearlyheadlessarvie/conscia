using Amazon.CDK;
using Amazon.CDK.AWS.EC2;
using Constructs;

namespace Conscia.Infra;

public class NetworkStack : Stack
{
    public IVpc Vpc { get; }
    public ISecurityGroup DbSecurityGroup { get; }

    public NetworkStack(Construct scope, string id, IStackProps? props = null)
        : base(scope, id, props)
    {
        Vpc = new Vpc(this, "ConsciaVpc", new VpcProps
        {
            MaxAzs = 2,
            NatGateways = 0,
            SubnetConfiguration =
            [
                new SubnetConfiguration
                {
                    Name = "Private-Isolated",
                    SubnetType = SubnetType.PRIVATE_ISOLATED,
                    CidrMask = 24
                },
                new SubnetConfiguration
                {
                    Name = "Public",
                    SubnetType = SubnetType.PUBLIC,
                    CidrMask = 24
                }
            ]
        });

        DbSecurityGroup = new SecurityGroup(this, "DbSecurityGroup", new SecurityGroupProps
        {
            Vpc = Vpc,
            Description = "Security group for RDS PostgreSQL",
            AllowAllOutbound = false
        });

        var isolatedSubnets = new SubnetSelection { SubnetType = SubnetType.PRIVATE_ISOLATED };

        // Gateway endpoints (free)
        Vpc.AddGatewayEndpoint("DynamoDbEndpoint", new GatewayVpcEndpointOptions
        {
            Service = GatewayVpcEndpointAwsService.DYNAMODB,
            Subnets = [isolatedSubnets]
        });

        Vpc.AddGatewayEndpoint("S3Endpoint", new GatewayVpcEndpointOptions
        {
            Service = GatewayVpcEndpointAwsService.S3,
            Subnets = [isolatedSubnets]
        });

        new CfnOutput(this, "VpcId", new CfnOutputProps { Value = Vpc.VpcId });
    }
}
