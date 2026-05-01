using Amazon.CDK;
using Amazon.CDK.AWS.Cognito;
using Constructs;

namespace Conscia.Infra;

public class AuthStack : Stack
{
    public IUserPool UserPool { get; }
    public IUserPoolClient UserPoolClient { get; }

    public AuthStack(Construct scope, string id, IStackProps? props = null)
        : base(scope, id, props)
    {
        UserPool = new UserPool(this, "ConsciaUserPool", new UserPoolProps
        {
            UserPoolName = "conscia-users",
            SelfSignUpEnabled = true,
            SignInAliases = new SignInAliases { Email = true },
            AutoVerify = new AutoVerifiedAttrs { Email = true },
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

        new CfnOutput(this, "UserPoolId", new CfnOutputProps { Value = UserPool.UserPoolId });
        new CfnOutput(this, "UserPoolClientId", new CfnOutputProps { Value = UserPoolClient.UserPoolClientId });
    }
}
