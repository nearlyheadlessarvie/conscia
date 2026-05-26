using Amazon.CDK;
using Amazon.CDK.AWS.IAM;
using Constructs;

namespace Conscia.Infra;

public class CiCdStackProps : StackProps
{
    public required string GitHubOrg { get; set; }
    public required string GitHubRepo { get; set; }
}

public class CiCdStack : Stack
{
    public CiCdStack(Construct scope, string id, CiCdStackProps props)
        : base(scope, id, props)
    {
        var oidcProvider = new OpenIdConnectProvider(this, "GitHubOidc", new OpenIdConnectProviderProps
        {
            Url = "https://token.actions.githubusercontent.com",
            ClientIds = new[] { "sts.amazonaws.com" }
        });

        var deployRole = new Role(this, "GitHubActionsRole", new RoleProps
        {
            RoleName = "conscia-github-actions",
            AssumedBy = new FederatedPrincipal(
                oidcProvider.OpenIdConnectProviderArn,
                new Dictionary<string, object>
                {
                    ["StringEquals"] = new Dictionary<string, string>
                    {
                        ["token.actions.githubusercontent.com:aud"] = "sts.amazonaws.com"
                    },
                    ["StringLike"] = new Dictionary<string, string>
                    {
                        ["token.actions.githubusercontent.com:sub"] = $"repo:{props.GitHubOrg}/{props.GitHubRepo}:*"
                    }
                },
                "sts:AssumeRoleWithWebIdentity"
            ),
            Description = "Role for GitHub Actions CI/CD deployments",
            MaxSessionDuration = Duration.Hours(1)
        });

        deployRole.AddToPolicy(new PolicyStatement(new PolicyStatementProps
        {
            Actions = new[]
            {
                "s3:PutObject", "s3:DeleteObject", "s3:ListBucket", "s3:GetObject",
                "cloudfront:CreateInvalidation", "cloudfront:GetDistribution"
            },
            Resources = new[] { "*" }
        }));

        deployRole.AddToPolicy(new PolicyStatement(new PolicyStatementProps
        {
            Actions = new[]
            {
                "cloudformation:*",
                "lambda:*",
                "iam:PassRole",
                "sts:AssumeRole"
            },
            Resources = new[] { "*" }
        }));

        deployRole.AddToPolicy(new PolicyStatement(new PolicyStatementProps
        {
            Actions = new[]
            {
                "secretsmanager:CreateSecret",
                "secretsmanager:DescribeSecret",
                "secretsmanager:GetSecretValue",
                "secretsmanager:PutSecretValue",
                "secretsmanager:TagResource",
                "secretsmanager:UpdateSecret"
            },
            Resources = new[]
            {
                $"arn:aws:secretsmanager:{Region}:{Account}:secret:conscia/prod/*"
            }
        }));

        deployRole.AddToPolicy(new PolicyStatement(new PolicyStatementProps
        {
            Actions = new[] { "ssm:GetParameter" },
            Resources = new[] { $"arn:aws:ssm:{Region}:{Account}:parameter/cdk-bootstrap/*" }
        }));

        new CfnOutput(this, "GitHubActionsRoleArn", new CfnOutputProps
        {
            Value = deployRole.RoleArn,
            Description = "ARN of the GitHub Actions deploy role",
            ExportName = "ConsciaGitHubActionsRoleArn"
        });
    }
}
