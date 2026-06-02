using Amazon.CDK;
using Amazon.CDK.AWS.CertificateManager;
using Amazon.CDK.AWS.Cognito;
using Amazon.CDK.AWS.IAM;
using Amazon.CDK.AWS.KMS;
using Amazon.CDK.AWS.Lambda;
using Amazon.CDK.AWS.Route53;
using Amazon.CDK.AWS.Route53.Targets;
using Constructs;

namespace Conscia.Infra;

public sealed class AuthStackProps : StackProps
{
    public string? CognitoCustomEmailSenderAssetPath { get; init; }
    public string? CognitoPreSignupLinkerAssetPath { get; init; }
    public DomainSettings? DomainSettings { get; init; }
    public ManagedLoginProviderSettings? ManagedLoginProviderSettings { get; init; }
    public ProductionRuntimeSettings? RuntimeSettings { get; init; }
}

public class AuthStack : Stack
{
    public IUserPool UserPool { get; }
    public IUserPoolClient UserPoolClient { get; }

    public AuthStack(Construct scope, string id, AuthStackProps? props = null)
        : base(scope, id, props)
    {
        var rootDomainName = props?.DomainSettings?.RootDomainName ?? "getconscia.com";
        var cognitoDomainName = props?.DomainSettings?.ResolvedCognitoDomainName ?? $"login.{rootDomainName}";
        var devRedirectUri = props?.DomainSettings?.DevManagedLoginRedirectUri ?? "conscia://auth/callback";
        var devLogoutUri = props?.DomainSettings?.DevManagedLoginLogoutUri ?? "conscia://auth/logout";
        var redirectUri = props?.DomainSettings?.ResolvedManagedLoginRedirectUri ?? devRedirectUri;
        var logoutUri = props?.DomainSettings?.ResolvedManagedLoginLogoutUri ?? devLogoutUri;
        var hasFederatedProviders = props?.ManagedLoginProviderSettings?.HasGoogle == true
            || props?.ManagedLoginProviderSettings?.HasApple == true;
        Function? preSignupLinker = null;
        Function? customEmailSender = null;
        Key? customEmailSenderKey = null;

        if (props?.RuntimeSettings is not null)
        {
            var customEmailSenderAssetPath = props.CognitoCustomEmailSenderAssetPath
                ?? AssetPathResolver.ResolvePublishedAsset("../publish/cognito-custom-email-sender", "cognito-custom-email-sender");
            customEmailSenderKey = new Key(this, "CognitoCustomEmailSenderKey", new KeyProps
            {
                Description = "Encrypts Cognito custom email sender codes and temporary passwords.",
                EnableKeyRotation = true,
                RemovalPolicy = RemovalPolicy.RETAIN
            });
            var brevoSenderEmail = props.RuntimeSettings.BrevoSenderEmail
                ?? props.RuntimeSettings.InviteEmailFromEmail
                ?? (props.DomainSettings is null ? string.Empty : $"no-reply@{rootDomainName}");

            customEmailSender = new Function(this, "CognitoCustomEmailSender", new FunctionProps
            {
                FunctionName = "conscia-cognito-custom-email-sender",
                Runtime = Runtime.DOTNET_8,
                Handler = "Conscia.CognitoCustomEmailSender",
                Code = Code.FromAsset(customEmailSenderAssetPath),
                MemorySize = 512,
                Timeout = Duration.Seconds(30),
                Architecture = Architecture.ARM_64,
                Environment = new Dictionary<string, string>
                {
                    ["COGNITO_CUSTOM_SENDER_KMS_KEY_ARN"] = customEmailSenderKey.KeyArn,
                    ["Brevo__ApiKey"] = props.RuntimeSettings.BrevoApiKey ?? string.Empty,
                    ["Brevo__SenderEmail"] = brevoSenderEmail,
                    ["Brevo__SenderName"] = props.RuntimeSettings.BrevoSenderName
                },
                Tracing = Tracing.ACTIVE
            });
            customEmailSenderKey.GrantDecrypt(customEmailSender);
        }

        if (hasFederatedProviders)
        {
            var linkerAssetPath = props?.CognitoPreSignupLinkerAssetPath
                ?? AssetPathResolver.ResolvePublishedAsset("../publish/cognito-pre-signup-linker", "cognito-pre-signup-linker");

            preSignupLinker = new Function(this, "CognitoPreSignupLinker", new FunctionProps
            {
                FunctionName = "conscia-cognito-pre-signup-linker",
                Runtime = Runtime.DOTNET_8,
                Handler = "Conscia.CognitoPreSignupLinker",
                Code = Code.FromAsset(linkerAssetPath),
                MemorySize = 512,
                Timeout = Duration.Seconds(30),
                Architecture = Architecture.ARM_64,
                Tracing = Tracing.ACTIVE
            });
        }

        UserPool = new UserPool(this, "ConsciaUserPool", new UserPoolProps
        {
            UserPoolName = "conscia-users",
            SelfSignUpEnabled = true,
            SignInAliases = new SignInAliases { Email = true },
            AutoVerify = new AutoVerifiedAttrs { Email = true },
            Mfa = Mfa.OFF,
            PasswordPolicy = new PasswordPolicy
            {
                MinLength = 8,
                RequireLowercase = true,
                RequireUppercase = true,
                RequireDigits = true,
                RequireSymbols = false
            },
            AccountRecovery = AccountRecovery.EMAIL_ONLY,
            RemovalPolicy = RemovalPolicy.RETAIN
        });
        var userPoolResource = (CfnUserPool)(UserPool.Node.DefaultChild
            ?? throw new InvalidOperationException("User pool CloudFormation resource was not created."));
        userPoolResource.UserPoolTier = "ESSENTIALS";
        userPoolResource.AddPropertyOverride(
            "Policies.SignInPolicy.AllowedFirstAuthFactors",
            new[] { "PASSWORD", "WEB_AUTHN" });
        userPoolResource.WebAuthnRelyingPartyId = rootDomainName;
        userPoolResource.WebAuthnUserVerification = "preferred";
        if (customEmailSender is not null && customEmailSenderKey is not null)
        {
            userPoolResource.LambdaConfig = new CfnUserPool.LambdaConfigProperty
            {
                PreSignUp = preSignupLinker?.FunctionArn,
                CustomEmailSender = new CfnUserPool.CustomEmailSenderProperty
                {
                    LambdaArn = customEmailSender.FunctionArn,
                    LambdaVersion = "V1_0"
                },
                KmsKeyId = customEmailSenderKey.KeyArn
            };
            customEmailSender.AddPermission("AllowCognitoInvokeCustomEmailSender", new Permission
            {
                Principal = new ServicePrincipal("cognito-idp.amazonaws.com"),
                SourceArn = UserPool.UserPoolArn
            });
        }
        else if (preSignupLinker is not null)
        {
            userPoolResource.LambdaConfig = new CfnUserPool.LambdaConfigProperty
            {
                PreSignUp = preSignupLinker.FunctionArn
            };
        }

        if (preSignupLinker is not null)
        {
            preSignupLinker.AddToRolePolicy(new PolicyStatement(new PolicyStatementProps
            {
                Actions =
                [
                    "cognito-idp:AdminCreateUser",
                    "cognito-idp:AdminLinkProviderForUser",
                    "cognito-idp:AdminSetUserPassword",
                    "cognito-idp:ListUsers"
                ],
                Resources =
                [
                    "*"
                ]
            }));
            preSignupLinker.AddPermission("AllowCognitoInvokePreSignUp", new Permission
            {
                Principal = new ServicePrincipal("cognito-idp.amazonaws.com"),
                SourceArn = UserPool.UserPoolArn
            });
        }

        var supportedIdentityProviders = new List<UserPoolClientIdentityProvider>
        {
            UserPoolClientIdentityProvider.COGNITO
        };
        var identityProviderResources = new List<CfnResource>();
        CfnParameter? managedLoginGoogleClientSecretParameter = null;
        CfnParameter? managedLoginApplePrivateKeyParameter = null;

        if (props?.ManagedLoginProviderSettings?.HasGoogle == true)
        {
            supportedIdentityProviders.Add(UserPoolClientIdentityProvider.GOOGLE);
            managedLoginGoogleClientSecretParameter = new CfnParameter(this, "ManagedLoginGoogleClientSecret", new CfnParameterProps
            {
                Type = "String",
                NoEcho = true
            });

            var googleProvider = new UserPoolIdentityProviderGoogle(this, "ManagedLoginGoogleProvider", new UserPoolIdentityProviderGoogleProps
            {
                UserPool = UserPool,
                ClientId = props.ManagedLoginProviderSettings.GoogleClientId!,
                ClientSecretValue = SecretValue.UnsafePlainText(managedLoginGoogleClientSecretParameter.ValueAsString),
                Scopes = ["openid", "email", "profile"],
                AttributeMapping = new AttributeMapping
                {
                    Email = ProviderAttribute.GOOGLE_EMAIL,
                    EmailVerified = ProviderAttribute.GOOGLE_EMAIL_VERIFIED,
                    GivenName = ProviderAttribute.GOOGLE_GIVEN_NAME,
                    FamilyName = ProviderAttribute.GOOGLE_FAMILY_NAME,
                    Fullname = ProviderAttribute.GOOGLE_NAME
                }
            });

            identityProviderResources.Add((CfnResource)(googleProvider.Node.DefaultChild
                ?? throw new InvalidOperationException("Google identity provider CloudFormation resource was not created.")));
        }

        if (props?.ManagedLoginProviderSettings?.HasApple == true)
        {
            supportedIdentityProviders.Add(UserPoolClientIdentityProvider.APPLE);
            managedLoginApplePrivateKeyParameter = new CfnParameter(this, "ManagedLoginApplePrivateKey", new CfnParameterProps
            {
                Type = "String",
                NoEcho = true
            });

            var appleProvider = new UserPoolIdentityProviderApple(this, "ManagedLoginAppleProvider", new UserPoolIdentityProviderAppleProps
            {
                UserPool = UserPool,
                ClientId = props.ManagedLoginProviderSettings.AppleServicesId!,
                TeamId = props.ManagedLoginProviderSettings.AppleTeamId!,
                KeyId = props.ManagedLoginProviderSettings.AppleKeyId!,
                PrivateKeyValue = SecretValue.UnsafePlainText(managedLoginApplePrivateKeyParameter.ValueAsString),
                Scopes = ["email", "name"],
                AttributeMapping = new AttributeMapping
                {
                    Email = ProviderAttribute.APPLE_EMAIL,
                    EmailVerified = ProviderAttribute.APPLE_EMAIL_VERIFIED,
                    GivenName = ProviderAttribute.APPLE_FIRST_NAME,
                    FamilyName = ProviderAttribute.APPLE_LAST_NAME,
                    Fullname = ProviderAttribute.APPLE_NAME
                }
            });

            identityProviderResources.Add((CfnResource)(appleProvider.Node.DefaultChild
                ?? throw new InvalidOperationException("Apple identity provider CloudFormation resource was not created.")));
        }

        UserPoolClient = new UserPoolClient(this, "ConsciaAppClient", new UserPoolClientProps
        {
            UserPool = UserPool,
            UserPoolClientName = "conscia-mobile",
            AuthFlows = new AuthFlow
            {
                UserPassword = true,
                UserSrp = true
            },
            SupportedIdentityProviders = supportedIdentityProviders.ToArray(),
            OAuth = new OAuthSettings
            {
                DefaultRedirectUri = redirectUri,
                CallbackUrls =
                [
                    redirectUri,
                    devRedirectUri
                ],
                LogoutUrls =
                [
                    logoutUri,
                    devLogoutUri
                ],
                Flows = new OAuthFlows
                {
                    AuthorizationCodeGrant = true
                },
                Scopes =
                [
                    OAuthScope.OPENID,
                    OAuthScope.EMAIL,
                    OAuthScope.PROFILE,
                    OAuthScope.COGNITO_ADMIN
                ]
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
        foreach (var identityProviderResource in identityProviderResources)
        {
            userPoolClientResource.AddDependency(identityProviderResource);
        }

        if (props?.DomainSettings is not null)
        {
            var hostedZone = HostedZone.FromHostedZoneAttributes(this, "CognitoHostedZone", new HostedZoneAttributes
            {
                HostedZoneId = props.DomainSettings.HostedZoneId,
                ZoneName = props.DomainSettings.RootDomainName
            });

            var certificate = new DnsValidatedCertificate(this, "ManagedLoginCertificate", new DnsValidatedCertificateProps
            {
                DomainName = cognitoDomainName,
                HostedZone = hostedZone,
                Region = "us-east-1",
                CleanupRoute53Records = true
            });

            var domain = UserPool.AddDomain("ManagedLoginDomain", new UserPoolDomainOptions
            {
                CustomDomain = new CustomDomainOptions
                {
                    DomainName = cognitoDomainName,
                    Certificate = certificate
                }
            });
            var domainResource = (CfnUserPoolDomain)(domain.Node.DefaultChild
                ?? throw new InvalidOperationException("User pool domain CloudFormation resource was not created."));
            domainResource.ManagedLoginVersion = 2;

            _ = new CfnResource(this, "ManagedLoginTermsOfUse", new CfnResourceProps
            {
                Type = "AWS::Cognito::Terms",
                Properties = new Dictionary<string, object>
                {
                    ["UserPoolId"] = UserPool.UserPoolId,
                    ["ClientId"] = UserPoolClient.UserPoolClientId,
                    ["TermsName"] = "terms-of-use",
                    ["TermsSource"] = "LINK",
                    ["Enforcement"] = "NONE",
                    ["Links"] = new Dictionary<string, string>
                    {
                        ["cognito:default"] = $"https://{rootDomainName}/terms"
                    }
                }
            });

            _ = new CfnResource(this, "ManagedLoginPrivacyPolicy", new CfnResourceProps
            {
                Type = "AWS::Cognito::Terms",
                Properties = new Dictionary<string, object>
                {
                    ["UserPoolId"] = UserPool.UserPoolId,
                    ["ClientId"] = UserPoolClient.UserPoolClientId,
                    ["TermsName"] = "privacy-policy",
                    ["TermsSource"] = "LINK",
                    ["Enforcement"] = "NONE",
                    ["Links"] = new Dictionary<string, string>
                    {
                        ["cognito:default"] = $"https://{rootDomainName}/privacy"
                    }
                }
            });

            _ = new ARecord(this, "ManagedLoginAliasRecord", new ARecordProps
            {
                Zone = hostedZone,
                RecordName = cognitoDomainName,
                Target = RecordTarget.FromAlias(new UserPoolDomainTarget(domain))
            });
        }

        new CfnOutput(this, "UserPoolId", new CfnOutputProps { Value = UserPool.UserPoolId });
        new CfnOutput(this, "UserPoolClientId", new CfnOutputProps { Value = UserPoolClient.UserPoolClientId });
    }
}
