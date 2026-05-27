using Amazon.CDK;
using Amazon.CDK.AWS.Cognito;
using Constructs;

namespace Conscia.Infra;

public sealed class AuthStackProps : StackProps
{
    public DomainSettings? DomainSettings { get; init; }
}

public class AuthStack : Stack
{
    public IUserPool UserPool { get; }
    public IUserPoolClient UserPoolClient { get; }

    public AuthStack(Construct scope, string id, AuthStackProps? props = null)
        : base(scope, id, props)
    {
        var rootDomainName = props?.DomainSettings?.RootDomainName ?? "getconscia.com";
        var cognitoEmail = props?.DomainSettings is null
            ? null
            : UserPoolEmail.WithSES(new UserPoolSESOptions
            {
                ConfigurationSetName = "conscia-production",
                FromEmail = $"no-reply@{rootDomainName}",
                SesRegion = Region,
                SesVerifiedDomain = rootDomainName
            });

        UserPool = new UserPool(this, "ConsciaUserPool", new UserPoolProps
        {
            UserPoolName = "conscia-users",
            SelfSignUpEnabled = true,
            SignInAliases = new SignInAliases { Email = true },
            AutoVerify = new AutoVerifiedAttrs { Email = true },
            Email = cognitoEmail,
            PasswordPolicy = new PasswordPolicy
            {
                MinLength = 8,
                RequireLowercase = true,
                RequireUppercase = true,
                RequireDigits = true,
                RequireSymbols = false
            },
            AccountRecovery = AccountRecovery.EMAIL_ONLY,
            RemovalPolicy = RemovalPolicy.DESTROY
        });
        var userPoolResource = (CfnUserPool)(UserPool.Node.DefaultChild
            ?? throw new InvalidOperationException("User pool CloudFormation resource was not created."));
        userPoolResource.UserPoolTier = "ESSENTIALS";
        userPoolResource.AddPropertyOverride(
            "Policies.SignInPolicy.AllowedFirstAuthFactors",
            new[] { "PASSWORD", "WEB_AUTHN" });
        userPoolResource.WebAuthnRelyingPartyId = rootDomainName;
        userPoolResource.WebAuthnUserVerification = "preferred";

        UserPoolClient = new UserPoolClient(this, "ConsciaAppClient", new UserPoolClientProps
        {
            UserPool = UserPool,
            UserPoolClientName = "conscia-mobile",
            AuthFlows = new AuthFlow
            {
                UserPassword = true,
                UserSrp = true
            },
            GenerateSecret = false,
            AccessTokenValidity = Duration.Hours(1),
            IdTokenValidity = Duration.Hours(1),
            RefreshTokenValidity = Duration.Days(30)
        });
        var userPoolClientResource = (CfnUserPoolClient)(UserPoolClient.Node.DefaultChild
            ?? throw new InvalidOperationException("User pool client CloudFormation resource was not created."));
        userPoolClientResource.ExplicitAuthFlows =
        [
            "ALLOW_USER_PASSWORD_AUTH",
            "ALLOW_USER_SRP_AUTH",
            "ALLOW_REFRESH_TOKEN_AUTH",
            "ALLOW_USER_AUTH"
        ];

        new CfnOutput(this, "UserPoolId", new CfnOutputProps { Value = UserPool.UserPoolId });
        new CfnOutput(this, "UserPoolClientId", new CfnOutputProps { Value = UserPoolClient.UserPoolClientId });
    }
}
