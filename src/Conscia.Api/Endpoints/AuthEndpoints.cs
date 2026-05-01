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
        }).WithName("Register");

        group.MapPost("/login", async (HttpContext ctx, LoginRequest req, IAuthService auth) =>
        {
            if (string.IsNullOrWhiteSpace(req.Email) || string.IsNullOrWhiteSpace(req.Password))
                return Results.BadRequest(new { error = "Email and password are required" });

            var result = await auth.LoginAsync(req.Email, req.Password, ctx.RequestAborted);
            return result.Success
                ? Results.Ok(new { result.AccessToken, result.RefreshToken, result.UserId })
                : Results.Unauthorized();
        }).WithName("Login");

        return group;
    }
}

public record RegisterRequest(string Email, string Password);
public record LoginRequest(string Email, string Password);
