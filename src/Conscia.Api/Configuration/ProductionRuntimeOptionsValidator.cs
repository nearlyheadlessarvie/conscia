using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Options;

namespace Conscia.Api.Configuration;

public sealed class ProductionRuntimeOptionsValidator : IValidateOptions<ProductionRuntimeOptions>
{
    private readonly IConfiguration _configuration;
    private readonly IHostEnvironment _environment;

    public ProductionRuntimeOptionsValidator(
        IConfiguration configuration,
        IHostEnvironment environment)
    {
        _configuration = configuration;
        _environment = environment;
    }

    public ValidateOptionsResult Validate(string? name, ProductionRuntimeOptions options)
    {
        if (!_environment.IsProduction())
        {
            return ValidateOptionsResult.Success;
        }

        var errors = new List<string>();

        if (_configuration.GetValue<bool>("Auth:UseMock"))
        {
            errors.Add("Auth:UseMock must be false in production.");
        }

        Require(errors, "Auth:Cognito:ClientId");
        Require(errors, "Auth:Cognito:UserPoolId");
        Require(errors, "Auth:Cognito:SignupGuardToken");
        Require(errors, "Recaptcha:ApiKey");
        Require(errors, "Recaptcha:ProjectId");
        Require(errors, "Recaptcha:AllowedSiteKeys");

        if (options.RequireSubscriptionValidation)
        {
            Require(errors, "Apple:KeyId");
            Require(errors, "Apple:IssuerId");
            Require(errors, "Apple:BundleId");
            Require(errors, "Apple:PrivateKey");
            Require(errors, "GooglePlay:PackageName");
            Require(errors, "GooglePlay:ServiceAccountJson");
        }

        if (options.RequirePushNotifications)
        {
            Require(errors, "Firebase:AdminServiceAccountJson");
        }

        if (options.RequireInviteEmail)
        {
            Require(errors, "Brevo:ApiKey");
            Require(errors, "Brevo:SenderEmail");
        }

        if (options.RequireAppCompatibility)
        {
            Require(errors, "AppCompatibility:CurrentSupportedAppVersion");
            Require(errors, "AppCompatibility:PreviousSupportedAppVersion");
        }

        return errors.Count == 0
            ? ValidateOptionsResult.Success
            : ValidateOptionsResult.Fail(errors);
    }

    private void Require(List<string> errors, string key)
    {
        if (string.IsNullOrWhiteSpace(_configuration[key]))
        {
            errors.Add($"{key} must be configured in production.");
        }
    }
}
