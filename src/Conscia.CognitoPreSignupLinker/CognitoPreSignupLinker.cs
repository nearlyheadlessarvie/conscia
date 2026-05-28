using Amazon.CognitoIdentityProvider;
using Amazon.CognitoIdentityProvider.Model;
using Microsoft.Extensions.Logging;

namespace Conscia.CognitoPreSignupLinker;

public sealed class CognitoPreSignupLinker(
    IAmazonCognitoIdentityProvider cognito,
    ILogger<CognitoPreSignupLinker> logger)
{
    public async Task<CognitoPreSignupEvent> HandleAsync(CognitoPreSignupEvent request, CancellationToken ct)
    {
        if (!string.Equals(request.TriggerSource, "PreSignUp_ExternalProvider", StringComparison.Ordinal))
        {
            return request;
        }

        if (!TryGetTrustedSource(request, out var providerName, out var providerSubject))
        {
            return request;
        }

        var email = GetAttribute(request, "email");
        if (string.IsNullOrWhiteSpace(email) || !IsTrue(GetAttribute(request, "email_verified")))
        {
            return request;
        }

        var userPoolId = request.UserPoolId;
        if (string.IsNullOrWhiteSpace(userPoolId))
        {
            throw new InvalidOperationException("Pre-sign-up event did not include a userPoolId.");
        }

        var existingUser = await FindLocalUserByEmailAsync(userPoolId, email!, ct);
        if (existingUser is null)
        {
            return request;
        }

        logger.LogInformation(
            "Linking {ProviderName} identity for {Email} to local Cognito user {Username}.",
            providerName,
            email,
            existingUser.Username);

        await cognito.AdminLinkProviderForUserAsync(new AdminLinkProviderForUserRequest
        {
            UserPoolId = userPoolId,
            DestinationUser = new ProviderUserIdentifierType
            {
                ProviderName = "Cognito",
                ProviderAttributeValue = existingUser.Username
            },
            SourceUser = new ProviderUserIdentifierType
            {
                ProviderName = providerName,
                ProviderAttributeName = "Cognito_Subject",
                ProviderAttributeValue = providerSubject
            }
        }, ct);

        return request;
    }

    private async Task<UserType?> FindLocalUserByEmailAsync(string userPoolId, string email, CancellationToken ct)
    {
        var response = await cognito.ListUsersAsync(new ListUsersRequest
        {
            UserPoolId = userPoolId,
            Filter = $"email = \"{EscapeFilterValue(email)}\""
        }, ct);

        return response.Users.FirstOrDefault(IsLocalCognitoUser);
    }

    private static bool IsLocalCognitoUser(UserType user)
    {
        return !string.Equals(user.UserStatus?.ToString(), "EXTERNAL_PROVIDER", StringComparison.OrdinalIgnoreCase);
    }

    private static bool TryGetTrustedSource(
        CognitoPreSignupEvent request,
        out string providerName,
        out string providerSubject)
    {
        providerName = string.Empty;
        providerSubject = string.Empty;

        if (string.IsNullOrWhiteSpace(request.UserName))
        {
            return false;
        }

        var separatorIndex = request.UserName.IndexOf('_');
        if (separatorIndex <= 0 || separatorIndex == request.UserName.Length - 1)
        {
            return false;
        }

        providerName = request.UserName[..separatorIndex];
        providerSubject = request.UserName[(separatorIndex + 1)..];

        return providerName is "Google" or "SignInWithApple";
    }

    private static string? GetAttribute(CognitoPreSignupEvent request, string name)
    {
        return request.Request.UserAttributes.TryGetValue(name, out var value) ? value : null;
    }

    private static bool IsTrue(string? value)
    {
        return string.Equals(value, "true", StringComparison.OrdinalIgnoreCase);
    }

    private static string EscapeFilterValue(string value)
    {
        return value
            .Replace("\\", "\\\\", StringComparison.Ordinal)
            .Replace("\"", "\\\"", StringComparison.Ordinal);
    }
}
