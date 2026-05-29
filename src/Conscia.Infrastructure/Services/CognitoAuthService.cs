using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Amazon.CognitoIdentityProvider;
using Amazon.CognitoIdentityProvider.Model;
using Conscia.Application.Interfaces;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace Conscia.Infrastructure.Services;

/// <summary>
/// Production email/password auth backed by AWS Cognito.
/// </summary>
public class CognitoAuthService : IAuthService
{
    private readonly IAmazonCognitoIdentityProvider _cognito;
    private readonly IUserRepository _users;
    private readonly ILogger<CognitoAuthService> _logger;
    private readonly string _clientId;

    public CognitoAuthService(
        IConfiguration config,
        IAmazonCognitoIdentityProvider cognito,
        IUserRepository users,
        ILogger<CognitoAuthService> logger)
    {
        _cognito = cognito;
        _users = users;
        _logger = logger;
        _clientId = config["Auth:Cognito:ClientId"]
            ?? throw new InvalidOperationException("Auth:Cognito:ClientId not configured");
    }

    public async Task<AuthResult> RegisterAsync(string email, string password, CancellationToken ct = default)
    {
        email = NormalizeEmail(email);

        try
        {
            var response = await _cognito.SignUpAsync(new SignUpRequest
            {
                ClientId = _clientId,
                Username = email,
                Password = password,
                UserAttributes =
                [
                    new AttributeType { Name = "email", Value = email }
                ]
            }, ct);

            if (!Guid.TryParse(response.UserSub, out var userId))
            {
                _logger.LogError("Cognito returned a non-Guid sub for {Email}", email);
                return new AuthResult
                {
                    Success = false,
                    Email = email,
                    Error = "Authentication service returned an invalid user id"
                };
            }

            await EnsureLocalUserAsync(
                userId,
                email,
                AuthProvider.Email,
                email,
                response.UserConfirmed == true,
                ct);

            return new AuthResult
            {
                Success = true,
                RequiresConfirmation = response.UserConfirmed != true,
                UserId = userId.ToString(),
                Email = email
            };
        }
        catch (UsernameExistsException)
        {
            return await ResendForExistingRegistrationAsync(email, ct);
        }
        catch (InvalidPasswordException ex)
        {
            return new AuthResult
            {
                Success = false,
                RequiresConfirmation = true,
                Email = email,
                Error = ex.Message
            };
        }
        catch (InvalidParameterException ex)
        {
            return new AuthResult
            {
                Success = false,
                RequiresConfirmation = true,
                Email = email,
                Error = ex.Message
            };
        }
        catch (AmazonCognitoIdentityProviderException ex)
        {
            _logger.LogError(ex, "Cognito signup failed for {Email}", email);
            return new AuthResult
            {
                Success = false,
                RequiresConfirmation = true,
                Email = email,
                Error = "Unable to register right now"
            };
        }
    }

    public async Task<AuthResult> ConfirmRegistrationAsync(string email, string confirmationCode, CancellationToken ct = default)
    {
        email = NormalizeEmail(email);

        try
        {
            await _cognito.ConfirmSignUpAsync(new ConfirmSignUpRequest
            {
                ClientId = _clientId,
                Username = email,
                ConfirmationCode = confirmationCode.Trim()
            }, ct);

            var user = await _users.GetByEmailAsync(email, ct);
            if (user is not null && !user.EmailConfirmed)
            {
                user.EmailConfirmed = true;
                await _users.UpdateAsync(user, ct);
            }

            return new AuthResult
            {
                Success = true,
                RequiresConfirmation = false,
                Email = email
            };
        }
        catch (CodeMismatchException)
        {
            return ConfirmationError(email, "Invalid confirmation code");
        }
        catch (ExpiredCodeException)
        {
            return ConfirmationError(email, "Confirmation code expired");
        }
        catch (UserNotFoundException)
        {
            return ConfirmationError(email, "User not found");
        }
        catch (AmazonCognitoIdentityProviderException ex)
        {
            _logger.LogError(ex, "Cognito confirmation failed for {Email}", email);
            return ConfirmationError(email, "Unable to confirm email right now");
        }
    }

    public async Task<AuthResult> ResendConfirmationAsync(string email, CancellationToken ct = default)
    {
        email = NormalizeEmail(email);

        try
        {
            await _cognito.ResendConfirmationCodeAsync(new ResendConfirmationCodeRequest
            {
                ClientId = _clientId,
                Username = email
            }, ct);

            return new AuthResult
            {
                Success = true,
                RequiresConfirmation = true,
                Email = email
            };
        }
        catch (UserNotFoundException)
        {
            return ConfirmationError(email, "User not found");
        }
        catch (InvalidParameterException ex) when (ex.Message.Contains("confirm", StringComparison.OrdinalIgnoreCase))
        {
            return new AuthResult
            {
                Success = false,
                RequiresConfirmation = false,
                Email = email,
                Error = "Account already exists. Please sign in."
            };
        }
        catch (AmazonCognitoIdentityProviderException ex)
        {
            _logger.LogError(ex, "Cognito resend confirmation failed for {Email}", email);
            return ConfirmationError(email, "Unable to resend confirmation code right now");
        }
    }

    public async Task<AuthResult> StartPasswordResetAsync(string email, CancellationToken ct = default)
    {
        email = NormalizeEmail(email);

        try
        {
            await _cognito.ForgotPasswordAsync(new ForgotPasswordRequest
            {
                ClientId = _clientId,
                Username = email
            }, ct);

            return new AuthResult
            {
                Success = true,
                Email = email
            };
        }
        catch (UserNotFoundException)
        {
            return new AuthResult
            {
                Success = true,
                Email = email
            };
        }
        catch (AmazonCognitoIdentityProviderException ex)
        {
            _logger.LogError(ex, "Cognito password reset start failed for {Email}", email);
            return new AuthResult
            {
                Success = false,
                Email = email,
                Error = "Unable to start password reset right now"
            };
        }
    }

    public async Task<AuthResult> ConfirmPasswordResetAsync(
        string email,
        string confirmationCode,
        string password,
        CancellationToken ct = default)
    {
        email = NormalizeEmail(email);

        try
        {
            await _cognito.ConfirmForgotPasswordAsync(new ConfirmForgotPasswordRequest
            {
                ClientId = _clientId,
                Username = email,
                ConfirmationCode = confirmationCode.Trim(),
                Password = password
            }, ct);

            var user = await _users.GetByEmailAsync(email, ct);
            if (user is not null && !user.EmailConfirmed)
            {
                user.EmailConfirmed = true;
                await _users.UpdateAsync(user, ct);
            }

            return new AuthResult
            {
                Success = true,
                Email = email,
                UserId = user?.Id.ToString()
            };
        }
        catch (CodeMismatchException)
        {
            return PasswordResetError(email, "Invalid confirmation code");
        }
        catch (ExpiredCodeException)
        {
            return PasswordResetError(email, "Confirmation code expired");
        }
        catch (InvalidPasswordException ex)
        {
            return PasswordResetError(email, ex.Message);
        }
        catch (AmazonCognitoIdentityProviderException ex)
        {
            _logger.LogError(ex, "Cognito password reset confirmation failed for {Email}", email);
            return PasswordResetError(email, "Unable to reset password right now");
        }
    }

    public async Task<AuthResult> LoginAsync(string email, string password, CancellationToken ct = default)
    {
        email = NormalizeEmail(email);

        try
        {
            var response = await _cognito.InitiateAuthAsync(new InitiateAuthRequest
            {
                ClientId = _clientId,
                AuthFlow = AuthFlowType.USER_PASSWORD_AUTH,
                AuthParameters = new Dictionary<string, string>
                {
                    ["USERNAME"] = email,
                    ["PASSWORD"] = password
                }
            }, ct);

            return await TokensToAuthResultAsync(response.AuthenticationResult, email, ct);
        }
        catch (UserNotConfirmedException)
        {
            return new AuthResult
            {
                Success = false,
                RequiresConfirmation = true,
                Email = email,
                Error = "Email confirmation required"
            };
        }
        catch (NotAuthorizedException)
        {
            return new AuthResult { Success = false, Email = email, Error = "Invalid credentials" };
        }
        catch (UserNotFoundException)
        {
            return new AuthResult { Success = false, Email = email, Error = "Invalid credentials" };
        }
        catch (AmazonCognitoIdentityProviderException ex)
        {
            _logger.LogError(ex, "Cognito login failed for {Email}", email);
            return new AuthResult { Success = false, Email = email, Error = "Unable to sign in right now" };
        }
    }

    public async Task<AuthResult> RefreshAsync(string refreshToken, CancellationToken ct = default)
    {
        try
        {
            var response = await _cognito.InitiateAuthAsync(new InitiateAuthRequest
            {
                ClientId = _clientId,
                AuthFlow = AuthFlowType.REFRESH_TOKEN_AUTH,
                AuthParameters = new Dictionary<string, string>
                {
                    ["REFRESH_TOKEN"] = refreshToken
                }
            }, ct);

            var result = await TokensToAuthResultAsync(response.AuthenticationResult, null, ct);
            result.RefreshToken ??= refreshToken;
            return result;
        }
        catch (AmazonCognitoIdentityProviderException ex)
        {
            _logger.LogWarning(ex, "Cognito refresh failed");
            return new AuthResult { Success = false, Error = "Invalid refresh token" };
        }
    }

    private async Task<AuthResult> TokensToAuthResultAsync(AuthenticationResultType tokens, string? emailFallback, CancellationToken ct)
    {
        var tokenForClaims = !string.IsNullOrWhiteSpace(tokens.IdToken)
            ? tokens.IdToken
            : tokens.AccessToken;
        var (userId, email) = ReadClaims(tokenForClaims);
        email ??= emailFallback;

        if (userId is not null && email is not null)
        {
            await EnsureLocalUserAsync(userId.Value, email, AuthProvider.Email, email, true, ct);
        }

        return new AuthResult
        {
            Success = true,
            AccessToken = tokens.AccessToken,
            RefreshToken = tokens.RefreshToken,
            UserId = userId?.ToString(),
            Email = email
        };
    }

    private async Task EnsureLocalUserAsync(
        Guid userId,
        string email,
        AuthProvider provider,
        string providerSub,
        bool emailConfirmed,
        CancellationToken ct)
    {
        var user = await _users.GetByIdAsync(userId, ct) ??
            await _users.GetByEmailAsync(email, ct);

        if (user is null)
        {
            user = new User
            {
                Id = userId,
                Email = email,
                EmailConfirmed = emailConfirmed
            };
            await _users.AddAsync(user, ct);
        }
        else if (emailConfirmed && !user.EmailConfirmed)
        {
            user.EmailConfirmed = true;
            await _users.UpdateAsync(user, ct);
        }

        var existingIdentity = await _users.GetByProviderAsync(provider, providerSub, ct);
        if (existingIdentity is null)
        {
            await _users.AddIdentityAsync(new UserIdentity
            {
                Id = Guid.NewGuid(),
                UserId = user.Id,
                Provider = provider,
                ProviderSub = providerSub
            }, ct);
        }
    }

    private static (Guid? UserId, string? Email) ReadClaims(string? token)
    {
        if (string.IsNullOrWhiteSpace(token))
        {
            return (null, null);
        }

        var jwt = new JwtSecurityTokenHandler().ReadJwtToken(token);
        var sub = jwt.Claims.FirstOrDefault(c => c.Type == "sub")?.Value;
        var email = jwt.Claims.FirstOrDefault(c => c.Type == "email" || c.Type == ClaimTypes.Email)?.Value;

        return Guid.TryParse(sub, out var userId)
            ? (userId, email)
            : (null, email);
    }

    private static AuthResult ConfirmationError(string email, string error) =>
        new()
        {
            Success = false,
            RequiresConfirmation = true,
            Email = email,
            Error = error
        };

    private static AuthResult PasswordResetError(string email, string error) =>
        new()
        {
            Success = false,
            Email = email,
            Error = error
        };

    private async Task<AuthResult> ResendForExistingRegistrationAsync(string email, CancellationToken ct)
    {
        var resend = await ResendConfirmationAsync(email, ct);
        if (resend.Success)
        {
            return new AuthResult
            {
                Success = true,
                RequiresConfirmation = true,
                Email = email
            };
        }

        return resend;
    }

    private static string NormalizeEmail(string email) => email.Trim().ToLowerInvariant();
}
