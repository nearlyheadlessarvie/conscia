using Amazon.CognitoIdentityProvider;
using Amazon.CognitoIdentityProvider.Model;
using Microsoft.Extensions.Logging;
using System.Security.Cryptography;

namespace Conscia.CognitoPreSignupLinker;

public sealed class CognitoPreSignupLinker(
    IAmazonCognitoIdentityProvider cognito,
    ILogger<CognitoPreSignupLinker> logger,
    string? signupGuardToken = null)
{
    private const string SignupGuardMetadataKey = "conscia_signup_guard";

    public async Task<CognitoPreSignupEvent> HandleAsync(CognitoPreSignupEvent request, CancellationToken ct)
    {
        if (string.Equals(request.TriggerSource, "PreSignUp_SignUp", StringComparison.Ordinal))
        {
            ValidateBackendSignupGuard(request);
            await RejectEmailSignupForExistingSocialIdentityAsync(request, ct);
            return request;
        }

        if (!string.Equals(request.TriggerSource, "PreSignUp_ExternalProvider", StringComparison.Ordinal))
        {
            return request;
        }

        if (!TryGetTrustedSource(request, out var providerName, out var providerSubject))
        {
            return request;
        }

        var email = GetAttribute(request, "email")?.Trim().ToLowerInvariant();
        if (string.IsNullOrWhiteSpace(email) || !IsTrue(GetAttribute(request, "email_verified")))
        {
            throw new InvalidOperationException(
                "Social sign-in requires a verified email from Google or Apple.");
        }

        var userPoolId = request.UserPoolId;
        if (string.IsNullOrWhiteSpace(userPoolId))
        {
            throw new InvalidOperationException("Pre-sign-up event did not include a userPoolId.");
        }

        var existingUser = await FindLocalUserByEmailAsync(userPoolId, email, ct)
            ?? await CreateLocalAnchorUserAsync(userPoolId, email, ct);

        logger.LogInformation(
            "Linking {ProviderName} identity for {Email} to local Cognito user {Username}.",
            providerName,
            email,
            existingUser.Username);

        try
        {
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
        }
        catch (InvalidParameterException ex) when (IsAlreadyLinkedProvider(ex))
        {
            logger.LogInformation(
                "Skipping {ProviderName} link for {Email} because Cognito reports the source identity is already linked.",
                providerName,
                email);
        }

        return request;
    }

    private void ValidateBackendSignupGuard(CognitoPreSignupEvent request)
    {
        if (string.IsNullOrWhiteSpace(signupGuardToken))
        {
            return;
        }

        if (!request.Request.ClientMetadata.TryGetValue(SignupGuardMetadataKey, out var provided) ||
            !string.Equals(provided, signupGuardToken, StringComparison.Ordinal))
        {
            throw new InvalidOperationException(
                "Email signup must originate from the backend registration service.");
        }
    }

    private async Task RejectEmailSignupForExistingSocialIdentityAsync(CognitoPreSignupEvent request, CancellationToken ct)
    {
        var email = GetAttribute(request, "email")?.Trim().ToLowerInvariant();
        if (string.IsNullOrWhiteSpace(email))
        {
            return;
        }

        var userPoolId = request.UserPoolId;
        if (string.IsNullOrWhiteSpace(userPoolId))
        {
            throw new InvalidOperationException("Pre-sign-up event did not include a userPoolId.");
        }

        var users = await ListUsersByEmailAsync(userPoolId, email, ct);
        if (users.Any(IsExternalProviderUser))
        {
            throw new InvalidOperationException(
                "An account already exists for this email. Sign in with Google or Apple.");
        }
    }

    private async Task<UserType?> FindLocalUserByEmailAsync(string userPoolId, string email, CancellationToken ct)
    {
        var users = await ListUsersByEmailAsync(userPoolId, email, ct);

        return users.FirstOrDefault(IsLocalCognitoUser);
    }

    private async Task<IReadOnlyList<UserType>> ListUsersByEmailAsync(string userPoolId, string email, CancellationToken ct)
    {
        var response = await cognito.ListUsersAsync(new ListUsersRequest
        {
            UserPoolId = userPoolId,
            Filter = $"email = \"{EscapeFilterValue(email)}\""
        }, ct);

        return response.Users;
    }

    private async Task<UserType> CreateLocalAnchorUserAsync(string userPoolId, string email, CancellationToken ct)
    {
        var anchorPassword = GenerateAnchorPassword();
        var response = await cognito.AdminCreateUserAsync(new AdminCreateUserRequest
        {
            UserPoolId = userPoolId,
            Username = email,
            TemporaryPassword = anchorPassword,
            MessageAction = MessageActionType.SUPPRESS,
            UserAttributes =
            [
                new AttributeType { Name = "email", Value = email },
                new AttributeType { Name = "email_verified", Value = "true" }
            ]
        }, ct);

        if (response.User is null)
        {
            throw new InvalidOperationException("Cognito did not return the linked-user anchor.");
        }

        var username = string.IsNullOrWhiteSpace(response.User.Username)
            ? email
            : response.User.Username;
        response.User.Username = username;

        await cognito.AdminSetUserPasswordAsync(new AdminSetUserPasswordRequest
        {
            UserPoolId = userPoolId,
            Username = username,
            Password = anchorPassword,
            Permanent = true
        }, ct);

        return response.User;
    }

    private static string GenerateAnchorPassword()
    {
        Span<byte> bytes = stackalloc byte[32];
        RandomNumberGenerator.Fill(bytes);
        return $"A1a-{Convert.ToBase64String(bytes)}";
    }

    private static bool IsLocalCognitoUser(UserType user)
    {
        return !string.Equals(user.UserStatus?.ToString(), "EXTERNAL_PROVIDER", StringComparison.OrdinalIgnoreCase);
    }

    private static bool IsExternalProviderUser(UserType user)
    {
        if (string.Equals(user.UserStatus?.ToString(), "EXTERNAL_PROVIDER", StringComparison.OrdinalIgnoreCase))
        {
            return true;
        }

        return user.Username?.StartsWith("Google_", StringComparison.Ordinal) == true ||
            user.Username?.StartsWith("SignInWithApple_", StringComparison.Ordinal) == true;
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

    private static bool IsAlreadyLinkedProvider(InvalidParameterException ex)
    {
        return ex.Message.Contains("already linked", StringComparison.OrdinalIgnoreCase);
    }

    private static string EscapeFilterValue(string value)
    {
        return value
            .Replace("\\", "\\\\", StringComparison.Ordinal)
            .Replace("\"", "\\\"", StringComparison.Ordinal);
    }
}
