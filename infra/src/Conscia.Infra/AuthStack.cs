using Amazon.CDK;
using Amazon.CDK.AWS.CertificateManager;
using Amazon.CDK.AWS.Cognito;
using Amazon.CDK.AWS.IAM;
using Amazon.CDK.AWS.Lambda;
using Amazon.CDK.AWS.Route53;
using Amazon.CDK.AWS.Route53.Targets;
using Constructs;
using System.Text;

namespace Conscia.Infra;

public sealed class AuthStackProps : StackProps
{
    public string? CognitoPreSignupLinkerAssetPath { get; init; }
    public DomainSettings? DomainSettings { get; init; }
    public ManagedLoginProviderSettings? ManagedLoginProviderSettings { get; init; }
    public ManagedLoginSecretSettings? ManagedLoginSecretSettings { get; init; }
}

public class AuthStack : Stack
{
    public IUserPool UserPool { get; }
    public IUserPoolClient UserPoolClient { get; }
    private const string LightInk = "1f2655ff";
    private const string LightMuted = "655b63ff";
    private const string LightSurface = "fffaf4ff";
    private const string LightSurfaceBorder = "e5d9ceff";
    private const string LightFocus = "c59e4bff";
    private const string LightDivider = "e6ddd5ff";
    private const string DarkInk = "f6efe6ff";
    private const string DarkMuted = "d3c6bcff";
    private const string DarkSurface = "171a2cff";
    private const string DarkSurfaceBorder = "353a5bff";
    private const string DarkFocus = "f0d58cff";
    private const string DarkDivider = "343a58ff";

    public AuthStack(Construct scope, string id, AuthStackProps? props = null)
        : base(scope, id, props)
    {
        var rootDomainName = props?.DomainSettings?.RootDomainName ?? "getconscia.com";
        var authDomainName = props?.DomainSettings?.ResolvedAuthDomainName ?? $"auth.{rootDomainName}";
        var cognitoDomainName = props?.DomainSettings?.ResolvedCognitoDomainName ?? $"login.{rootDomainName}";
        var redirectUri = props?.DomainSettings?.ResolvedManagedLoginRedirectUri ?? $"https://{authDomainName}/open/auth/callback";
        var logoutUri = props?.DomainSettings?.ResolvedManagedLoginLogoutUri ?? $"https://{authDomainName}/open/auth/logout";
        var devRedirectUri = props?.DomainSettings?.DevManagedLoginRedirectUri ?? "conscia://auth/callback";
        var devLogoutUri = props?.DomainSettings?.DevManagedLoginLogoutUri ?? "conscia://auth/logout";
        var hasFederatedProviders = props?.ManagedLoginProviderSettings?.HasGoogle == true
            || props?.ManagedLoginProviderSettings?.HasApple == true;
        var cognitoEmail = props?.DomainSettings is null
            ? null
            : UserPoolEmail.WithSES(new UserPoolSESOptions
            {
                ConfigurationSetName = "conscia-production",
                FromEmail = $"no-reply@{rootDomainName}",
                SesRegion = Region,
                SesVerifiedDomain = rootDomainName
            });
        Function? preSignupLinker = null;

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
            Email = cognitoEmail,
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
            LambdaTriggers = preSignupLinker is null
                ? null
                : new UserPoolTriggers
                {
                    PreSignUp = preSignupLinker
                },
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

        if (preSignupLinker is not null)
        {
            preSignupLinker.AddToRolePolicy(new PolicyStatement(new PolicyStatementProps
            {
                Actions =
                [
                    "cognito-idp:AdminLinkProviderForUser",
                    "cognito-idp:ListUsers"
                ],
                Resources =
                [
                    "*"
                ]
            }));
        }

        var supportedIdentityProviders = new List<UserPoolClientIdentityProvider>
        {
            UserPoolClientIdentityProvider.COGNITO
        };
        var identityProviderResources = new List<CfnResource>();

        if (props?.ManagedLoginProviderSettings?.HasGoogle == true)
        {
            supportedIdentityProviders.Add(UserPoolClientIdentityProvider.GOOGLE);

            var googleProvider = new UserPoolIdentityProviderGoogle(this, "ManagedLoginGoogleProvider", new UserPoolIdentityProviderGoogleProps
            {
                UserPool = UserPool,
                ClientId = props.ManagedLoginProviderSettings.GoogleClientId!,
                ClientSecretValue = SecretValue.SecretsManager(
                    props.ManagedLoginSecretSettings?.GoogleClientSecretSecretName
                    ?? "conscia/prod/cognito-google-client-secret"),
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

            var appleProvider = new UserPoolIdentityProviderApple(this, "ManagedLoginAppleProvider", new UserPoolIdentityProviderAppleProps
            {
                UserPool = UserPool,
                ClientId = props.ManagedLoginProviderSettings.AppleServicesId!,
                TeamId = props.ManagedLoginProviderSettings.AppleTeamId!,
                KeyId = props.ManagedLoginProviderSettings.AppleKeyId!,
                PrivateKeyValue = SecretValue.SecretsManager(
                    props.ManagedLoginSecretSettings?.ApplePrivateKeySecretName
                    ?? "conscia/prod/apple-private-key"),
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

            _ = new CfnManagedLoginBranding(this, "ManagedLoginBranding", new CfnManagedLoginBrandingProps
            {
                UserPoolId = UserPool.UserPoolId,
                ClientId = UserPoolClient.UserPoolClientId,
                UseCognitoProvidedValues = false,
                ReturnMergedResources = false,
                Assets = BuildManagedLoginBrandingAssets(),
                Settings = BuildManagedLoginBrandingSettings()
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

    private static CfnManagedLoginBranding.AssetTypeProperty[] BuildManagedLoginBrandingAssets()
    {
        return
        [
            new CfnManagedLoginBranding.AssetTypeProperty
            {
                Category = "FORM_LOGO",
                ColorMode = "DYNAMIC",
                Extension = "SVG",
                Bytes = EncodeSvg(BuildDynamicLogoSvg())
            },
            new CfnManagedLoginBranding.AssetTypeProperty
            {
                Category = "PAGE_BACKGROUND",
                ColorMode = "LIGHT",
                Extension = "SVG",
                Bytes = EncodeSvg(BuildPageBackgroundSvg(
                    topColor: "#f8f2e9",
                    bottomColor: "#f4eadc",
                    glowColor: "#f0d58c",
                    accentColor: "#24346f"))
            },
            new CfnManagedLoginBranding.AssetTypeProperty
            {
                Category = "PAGE_BACKGROUND",
                ColorMode = "DARK",
                Extension = "SVG",
                Bytes = EncodeSvg(BuildPageBackgroundSvg(
                    topColor: "#141827",
                    bottomColor: "#0d1120",
                    glowColor: "#6d5e2b",
                    accentColor: "#f0d58c"))
            }
        ];
    }

    private static Dictionary<string, object> BuildManagedLoginBrandingSettings()
    {
        return new Dictionary<string, object>
        {
            ["categories"] = new Dictionary<string, object>
            {
                ["auth"] = new Dictionary<string, object>
                {
                    ["federation"] = new Dictionary<string, object>
                    {
                        ["interfaceStyle"] = "BUTTON_LIST"
                    }
                },
                ["form"] = new Dictionary<string, object>
                {
                    ["displayGraphics"] = true,
                    ["instructions"] = new Dictionary<string, object>
                    {
                        ["enabled"] = false
                    },
                    ["languageSelector"] = new Dictionary<string, object>
                    {
                        ["enabled"] = false
                    },
                    ["location"] = new Dictionary<string, object>
                    {
                        ["horizontal"] = "CENTER",
                        ["vertical"] = "CENTER"
                    }
                },
                ["global"] = new Dictionary<string, object>
                {
                    ["colorSchemeMode"] = "DYNAMIC",
                    ["pageFooter"] = new Dictionary<string, object>
                    {
                        ["enabled"] = false
                    },
                    ["pageHeader"] = new Dictionary<string, object>
                    {
                        ["enabled"] = false
                    },
                    ["spacingDensity"] = "REGULAR"
                }
            },
            ["componentClasses"] = new Dictionary<string, object>
            {
                ["buttons"] = new Dictionary<string, object>
                {
                    ["borderRadius"] = 28.0
                },
                ["divider"] = new Dictionary<string, object>
                {
                    ["lightMode"] = new Dictionary<string, object>
                    {
                        ["borderColor"] = LightDivider
                    },
                    ["darkMode"] = new Dictionary<string, object>
                    {
                        ["borderColor"] = DarkDivider
                    }
                },
                ["focusState"] = new Dictionary<string, object>
                {
                    ["lightMode"] = new Dictionary<string, object>
                    {
                        ["borderColor"] = LightFocus
                    },
                    ["darkMode"] = new Dictionary<string, object>
                    {
                        ["borderColor"] = DarkFocus
                    }
                },
                ["idpButtons"] = new Dictionary<string, object>
                {
                    ["icons"] = new Dictionary<string, object>
                    {
                        ["enabled"] = true
                    }
                },
                ["input"] = new Dictionary<string, object>
                {
                    ["borderRadius"] = 18.0,
                    ["lightMode"] = new Dictionary<string, object>
                    {
                        ["defaults"] = new Dictionary<string, object>
                        {
                            ["backgroundColor"] = LightSurface,
                            ["borderColor"] = LightSurfaceBorder
                        },
                        ["placeholderColor"] = LightMuted
                    },
                    ["darkMode"] = new Dictionary<string, object>
                    {
                        ["defaults"] = new Dictionary<string, object>
                        {
                            ["backgroundColor"] = DarkSurface,
                            ["borderColor"] = DarkSurfaceBorder
                        },
                        ["placeholderColor"] = DarkMuted
                    }
                },
                ["pageText"] = new Dictionary<string, object>
                {
                    ["lightMode"] = new Dictionary<string, object>
                    {
                        ["headingColor"] = LightInk,
                        ["bodyColor"] = LightMuted,
                        ["descriptionColor"] = LightMuted
                    },
                    ["darkMode"] = new Dictionary<string, object>
                    {
                        ["headingColor"] = DarkInk,
                        ["bodyColor"] = DarkMuted,
                        ["descriptionColor"] = DarkMuted
                    }
                }
            }
        };
    }

    private static string EncodeSvg(string svg) =>
        Convert.ToBase64String(Encoding.UTF8.GetBytes(svg));

    private static string BuildDynamicLogoSvg() =>
        """
        <svg width="160" height="160" viewBox="0 0 160 160" fill="none" xmlns="http://www.w3.org/2000/svg">
          <rect x="16" y="16" width="128" height="128" rx="36" fill="#FFF8EF"/>
          <path d="M78 40c-17 14-29 33-31 55 11-11 24-18 40-22-5 16-6 31-1 47 22-17 32-40 31-68-10-8-24-12-39-12Z" fill="#24346F"/>
          <path d="M98 47c13 11 21 26 22 46-9-6-18-10-29-12 3 10 3 20-1 31 16-11 25-28 26-49-5-8-11-13-18-16Z" fill="#E0AE52"/>
        </svg>
        """;

    private static string BuildPageBackgroundSvg(
        string topColor,
        string bottomColor,
        string glowColor,
        string accentColor) =>
        $$"""
        <svg width="1440" height="1200" viewBox="0 0 1440 1200" fill="none" xmlns="http://www.w3.org/2000/svg">
          <defs>
            <linearGradient id="bg" x1="0" y1="0" x2="1120" y2="1200" gradientUnits="userSpaceOnUse">
              <stop stop-color="{{topColor}}"/>
              <stop offset="1" stop-color="{{bottomColor}}"/>
            </linearGradient>
            <radialGradient id="glow" cx="0" cy="0" r="1" gradientUnits="userSpaceOnUse" gradientTransform="translate(1130 180) rotate(127) scale(410 360)">
              <stop stop-color="{{glowColor}}" stop-opacity="0.55"/>
              <stop offset="1" stop-color="{{glowColor}}" stop-opacity="0"/>
            </radialGradient>
            <radialGradient id="mist" cx="0" cy="0" r="1" gradientUnits="userSpaceOnUse" gradientTransform="translate(260 1030) rotate(-34) scale(520 320)">
              <stop stop-color="#FFFFFF" stop-opacity="0.24"/>
              <stop offset="1" stop-color="#FFFFFF" stop-opacity="0"/>
            </radialGradient>
          </defs>
          <rect width="1440" height="1200" fill="url(#bg)"/>
          <ellipse cx="1130" cy="180" rx="420" ry="320" fill="url(#glow)"/>
          <ellipse cx="260" cy="1030" rx="470" ry="280" fill="url(#mist)"/>
          <path d="M1034 104c96 34 180 118 216 214" stroke="{{accentColor}}" stroke-opacity="0.14" stroke-width="32" stroke-linecap="round"/>
        </svg>
        """;
}
