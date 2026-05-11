using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Amazon.CognitoIdentityProvider;
using Amazon.CognitoIdentityProvider.Model;
using Conscia.Application.Interfaces;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.IdentityModel.Tokens;

namespace Conscia.Infrastructure.Services;

/// <summary>
/// Production email/password auth backed by AWS Cognito.
/// </summary>
public class CognitoAuthService : IAuthService
{
    private readonly IAmazonCognitoIdentityProvider _cognito;
    private readonly IExternalSocialTokenVerifier _socialTokenVerifier;
    private readonly IUserRepository _users;
    private readonly ILogger<CognitoAuthService> _logger;
    private readonly string _clientId;
    private readonly string _userPoolId;
    private readonly string? _appJwtSigningKey;
    private readonly string _appJwtIssuer;
    private readonly string _appJwtAudience;

    public CognitoAuthService(
        IConfiguration config,
        IAmazonCognitoIdentityProvider cognito,
        IExternalSocialTokenVerifier socialTokenVerifier,
        IUserRepository users,
        ILogger<CognitoAuthService> logger)
    {
        _cognito = cognito;
        _socialTokenVerifier = socialTokenVerifier;
        _users = users;
        _logger = logger;
        _clientId = config["Auth:Cognito:ClientId"]
            ?? throw new InvalidOperationException("Auth:Cognito:ClientId not configured");
        _userPoolId = config["Auth:Cognito:UserPoolId"]
            ?? throw new InvalidOperationException("Auth:Cognito:UserPoolId not configured");
        _appJwtSigningKey = config["Auth:AppJwtSigningKey"];
        _appJwtIssuer = config["Auth:AppJwtIssuer"] ?? "conscia-app";
        _appJwtAudience = config["Auth:AppJwtAudience"] ?? "conscia-api";
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
                return new AuthResult { Success = false, Email = email, Error = "Authentication service returned an invalid user id" };
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
            return new AuthResult { Success = false, RequiresConfirmation = true, Email = email, Error = ex.Message };
        }
        catch (InvalidParameterException ex)
        {
            return new AuthResult { Success = false, RequiresConfirmation = true, Email = email, Error = ex.Message };
        }
        catch (AmazonCognitoIdentityProviderException ex)
        {
            _logger.LogError(ex, "Cognito signup failed for {Email}", email);
            return new AuthResult { Success = false, RequiresConfirmation = true, Email = email, Error = "Unable to register right now" };
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
        var appRefresh = await TryRefreshAppTokenAsync(refreshToken, ct);
        if (appRefresh is not null)
        {
            return appRefresh;
        }

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

    public async Task<AuthResult> LoginWithGoogleAsync(string idToken, CancellationToken ct = default)
    {
        var payload = await _socialTokenVerifier.VerifyGoogleAsync(idToken, ct);
        return payload is null
            ? new AuthResult { Success = false, Error = "Google sign-in could not be verified" }
            : await LoginWithSocialAsync(AuthProvider.Google, payload, ct);
    }

    public async Task<AuthResult> LoginWithAppleAsync(string identityToken, string? authorizationCode, CancellationToken ct = default)
    {
        var payload = await _socialTokenVerifier.VerifyAppleAsync(identityToken, ct);
        return payload is null
            ? new AuthResult { Success = false, Error = "Apple sign-in could not be verified" }
            : await LoginWithSocialAsync(AuthProvider.Apple, payload, ct);
    }

    public Task<ClaimsPrincipal?> ValidateTokenAsync(string token, CancellationToken ct = default)
    {
        // JWT bearer middleware performs production token validation through Cognito JWKS.
        return Task.FromResult<ClaimsPrincipal?>(null);
    }

    private async Task<AuthResult> LoginWithSocialAsync(
        AuthProvider provider,
        SocialTokenPayload payload,
        CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(_appJwtSigningKey))
        {
            return new AuthResult { Success = false, Error = "Social sign-in is not configured" };
        }

        var email = NormalizeEmail(payload.Email);
        var user = await _users.GetByProviderAsync(provider, payload.ProviderSub, ct);
        var createdUser = false;

        if (user is null)
        {
            user = await _users.GetByEmailAsync(email, ct);
            if (user is null)
            {
                user = new User
                {
                    Id = Guid.NewGuid(),
                    Email = email,
                    EmailConfirmed = payload.EmailVerified
                };
                await _users.AddAsync(user, ct);
                createdUser = true;
            }
            else if (payload.EmailVerified && !user.EmailConfirmed)
            {
                user.EmailConfirmed = true;
                await _users.UpdateAsync(user, ct);
            }

            try
            {
                await _users.AddIdentityAsync(new UserIdentity
                {
                    Id = Guid.NewGuid(),
                    UserId = user.Id,
                    Provider = provider,
                    ProviderSub = payload.ProviderSub
                }, ct);
            }
            catch (Microsoft.EntityFrameworkCore.DbUpdateException)
            {
                user = await _users.GetByProviderAsync(provider, payload.ProviderSub, ct);
                if (user is null)
                {
                    return new AuthResult { Success = false, Error = "Identity conflict. Please try again." };
                }
            }
        }

        if (createdUser)
        {
            var created = await TryCreateCognitoSocialUserAsync(user, payload.EmailVerified, ct);
            if (!created)
            {
                return new AuthResult { Success = false, Error = "Unable to create social account right now" };
            }
        }

        return IssueAppTokens(user);
    }

    private async Task<bool> TryCreateCognitoSocialUserAsync(User user, bool emailVerified, CancellationToken ct)
    {
        try
        {
            await _cognito.AdminCreateUserAsync(new AdminCreateUserRequest
            {
                UserPoolId = _userPoolId,
                Username = user.Id.ToString("D"),
                MessageAction = MessageActionType.SUPPRESS,
                UserAttributes =
                [
                    new AttributeType { Name = "email", Value = user.Email },
                    new AttributeType { Name = "email_verified", Value = emailVerified ? "true" : "false" }
                ]
            }, ct);
            return true;
        }
        catch (UsernameExistsException)
        {
            return true;
        }
        catch (AmazonCognitoIdentityProviderException ex)
        {
            _logger.LogError(ex, "Failed to create Cognito shadow user for social account {UserId}", user.Id);
            return false;
        }
    }

    private AuthResult IssueAppTokens(User user)
    {
        var accessToken = CreateAppJwt(user, DateTime.UtcNow.AddHours(1), "access");
        var refreshToken = CreateAppJwt(user, DateTime.UtcNow.AddDays(30), "refresh");
        return new AuthResult
        {
            Success = true,
            AccessToken = accessToken,
            RefreshToken = refreshToken,
            UserId = user.Id.ToString(),
            Email = user.Email
        };
    }

    private string CreateAppJwt(User user, DateTime expires, string tokenUse)
    {
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_appJwtSigningKey!));
        var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
        var claims = new[]
        {
            new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
            new Claim(ClaimTypes.Email, user.Email),
            new Claim("sub", user.Id.ToString()),
            new Claim("email", user.Email),
            new Claim("tier", "Free"),
            new Claim("token_use", tokenUse)
        };

        var token = new JwtSecurityToken(
            issuer: _appJwtIssuer,
            audience: _appJwtAudience,
            claims: claims,
            expires: expires,
            signingCredentials: credentials);

        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    private async Task<AuthResult?> TryRefreshAppTokenAsync(string refreshToken, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(_appJwtSigningKey))
        {
            return null;
        }

        try
        {
            var principal = new JwtSecurityTokenHandler().ValidateToken(refreshToken, new TokenValidationParameters
            {
                ValidateIssuerSigningKey = true,
                IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_appJwtSigningKey)),
                ValidateIssuer = true,
                ValidIssuer = _appJwtIssuer,
                ValidateAudience = true,
                ValidAudience = _appJwtAudience,
                ValidateLifetime = true,
                ClockSkew = TimeSpan.FromMinutes(1)
            }, out _);

            if (principal.FindFirst("token_use")?.Value != "refresh")
            {
                return null;
            }

            var sub = principal.FindFirst("sub")?.Value ?? principal.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!Guid.TryParse(sub, out var userId))
            {
                return null;
            }

            var user = await _users.GetByIdAsync(userId, ct);
            if (user is null)
            {
                return null;
            }

            var result = IssueAppTokens(user);
            result.RefreshToken = refreshToken;
            return result;
        }
        catch
        {
            return null;
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
        var user = await _users.GetByIdAsync(userId, ct);
        if (user is null)
        {
            user = await _users.GetByEmailAsync(email, ct);
        }

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

    private static AuthResult ConfirmationError(string email, string error)
    {
        return new AuthResult
        {
            Success = false,
            RequiresConfirmation = true,
            Email = email,
            Error = error
        };
    }

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
