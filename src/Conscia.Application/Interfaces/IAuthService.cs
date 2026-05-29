namespace Conscia.Application.Interfaces;

public interface IAuthService
{
    Task<AuthResult> RegisterAsync(string email, string password, CancellationToken ct = default);
    Task<AuthResult> ConfirmRegistrationAsync(string email, string confirmationCode, CancellationToken ct = default);
    Task<AuthResult> ResendConfirmationAsync(string email, CancellationToken ct = default);
    Task<AuthResult> StartPasswordResetAsync(string email, CancellationToken ct = default);
    Task<AuthResult> ConfirmPasswordResetAsync(string email, string confirmationCode, string password, CancellationToken ct = default);
    Task<AuthResult> LoginAsync(string email, string password, CancellationToken ct = default);
    Task<AuthResult> RefreshAsync(string refreshToken, CancellationToken ct = default);
}

public class AuthResult
{
    public bool Success { get; set; }
    public string? AccessToken { get; set; }
    public string? RefreshToken { get; set; }
    public string? UserId { get; set; }
    public string? Email { get; set; }
    public bool RequiresConfirmation { get; set; }
    public string? Error { get; set; }
}
