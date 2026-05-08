using System.Security.Claims;

namespace Conscia.Application.Interfaces;

public interface IAuthService
{
    Task<AuthResult> RegisterAsync(string email, string password, CancellationToken ct = default);
    Task<AuthResult> LoginAsync(string email, string password, CancellationToken ct = default);
    Task<AuthResult> RefreshAsync(string refreshToken, CancellationToken ct = default);
    Task<AuthResult> LoginWithGoogleAsync(string idToken, CancellationToken ct = default);
    Task<AuthResult> LoginWithAppleAsync(string identityToken, string? authorizationCode, CancellationToken ct = default);
    Task<ClaimsPrincipal?> ValidateTokenAsync(string token, CancellationToken ct = default);
}

public class AuthResult
{
    public bool Success { get; set; }
    public string? AccessToken { get; set; }
    public string? RefreshToken { get; set; }
    public string? UserId { get; set; }
    public string? Error { get; set; }
}
