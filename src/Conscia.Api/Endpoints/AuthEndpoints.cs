using Conscia.Application.Interfaces;

namespace Conscia.Api.Endpoints;

public static class AuthEndpoints
{
    public static RouteGroupBuilder MapAuthEndpoints(this IEndpointRouteBuilder routes)
    {
        var group = routes.MapGroup("/api/v1/auth").WithTags("Auth");

        group.MapPost("/register", async (HttpContext ctx, RegisterRequest req, IAuthService auth) =>
        {
            if (string.IsNullOrWhiteSpace(req.Email) || string.IsNullOrWhiteSpace(req.Password))
                return Results.BadRequest(new { error = "Email and password are required" });

            var result = await auth.RegisterAsync(req.Email, req.Password, ctx.RequestAborted);
            return result.Success
                ? Results.Created("/api/v1/users/me", new { result.AccessToken, result.RefreshToken, result.UserId })
                : Results.BadRequest(new { result.Error });
        }).WithName("Register").RequireRateLimiting("auth");

        group.MapPost("/login", async (HttpContext ctx, LoginRequest req, IAuthService auth) =>
        {
            if (string.IsNullOrWhiteSpace(req.Email) || string.IsNullOrWhiteSpace(req.Password))
                return Results.BadRequest(new { error = "Email and password are required" });

            var result = await auth.LoginAsync(req.Email, req.Password, ctx.RequestAborted);
            return result.Success
                ? Results.Ok(new { result.AccessToken, result.RefreshToken, result.UserId })
                : Results.Json(new { error = "Invalid email or password" }, statusCode: 401);
        }).WithName("Login").RequireRateLimiting("auth");

        group.MapPost("/google", async (HttpContext ctx, GoogleLoginRequest req, IAuthService auth) =>
        {
            if (string.IsNullOrWhiteSpace(req.IdToken))
                return Results.BadRequest(new { error = "IdToken is required" });

            var result = await auth.LoginWithGoogleAsync(req.IdToken, ctx.RequestAborted);
            return result.Success
                ? Results.Ok(new { result.AccessToken, result.RefreshToken, result.UserId })
                : Results.BadRequest(new { result.Error });
        }).WithName("GoogleLogin").RequireRateLimiting("standard");

        group.MapPost("/apple", async (HttpContext ctx, AppleLoginRequest req, IAuthService auth) =>
        {
            if (string.IsNullOrWhiteSpace(req.IdentityToken))
                return Results.BadRequest(new { error = "IdentityToken is required" });

            var result = await auth.LoginWithAppleAsync(req.IdentityToken, req.AuthorizationCode, ctx.RequestAborted);
            return result.Success
                ? Results.Ok(new { result.AccessToken, result.RefreshToken, result.UserId })
                : Results.BadRequest(new { result.Error });
        }).WithName("AppleLogin").RequireRateLimiting("standard");

        return group;
    }
}

public record RegisterRequest(string Email, string Password);
public record LoginRequest(string Email, string Password);
public record GoogleLoginRequest(string IdToken);
public record AppleLoginRequest(string IdentityToken, string? AuthorizationCode);
