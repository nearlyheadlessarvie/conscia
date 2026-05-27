using Asp.Versioning.Builder;
using Conscia.Application.DTOs;
using Conscia.Application.Exceptions;
using Conscia.Application.Interfaces;

namespace Conscia.Api.Endpoints;

public static class AuthEndpoints
{
    public static RouteGroupBuilder MapAuthEndpoints(this IEndpointRouteBuilder routes, ApiVersionSet apiVersionSet)
    {
        var group = routes.MapGroup("/api/auth")
            .WithApiVersionSet(apiVersionSet)
            .MapToApiVersion(1.0)
            .WithTags("Auth");

        group.MapPost("/register", async (HttpContext ctx, RegisterRequest req, IAuthService auth) =>
        {
            if (string.IsNullOrWhiteSpace(req.Email) || string.IsNullOrWhiteSpace(req.Password))
                return Results.BadRequest(new { error = "Email and password are required" });

            var result = await auth.RegisterAsync(req.Email, req.Password, ctx.RequestAborted);
            return result.Success
                ? Results.Accepted(
                    "/api/auth/confirm",
                    new { result.Success, result.RequiresConfirmation, result.Email, result.UserId })
                : Results.BadRequest(new { result.Error });
        }).WithName("Register").RequireRateLimiting("auth");

        group.MapPost("/confirm", async (HttpContext ctx, ConfirmRegistrationRequest req, IAuthService auth) =>
        {
            if (string.IsNullOrWhiteSpace(req.Email) || string.IsNullOrWhiteSpace(req.ConfirmationCode))
                return Results.BadRequest(new { error = "Email and confirmation code are required" });

            var result = await auth.ConfirmRegistrationAsync(
                req.Email,
                req.ConfirmationCode,
                ctx.RequestAborted);

            return result.Success
                ? Results.Ok(new { result.Success, result.Email, result.UserId })
                : Results.BadRequest(new { result.Error, result.RequiresConfirmation });
        }).WithName("ConfirmRegistration").RequireRateLimiting("auth");

        group.MapPost("/resend-confirmation", async (HttpContext ctx, ResendConfirmationRequest req, IAuthService auth) =>
        {
            if (string.IsNullOrWhiteSpace(req.Email))
                return Results.BadRequest(new { error = "Email is required" });

            var result = await auth.ResendConfirmationAsync(req.Email, ctx.RequestAborted);
            return result.Success
                ? Results.Ok(new { result.Success, result.RequiresConfirmation, result.Email })
                : Results.BadRequest(new { result.Error });
        }).WithName("ResendConfirmation").RequireRateLimiting("auth");

        group.MapPost("/login", async (HttpContext ctx, LoginRequest req, IAuthService auth) =>
        {
            if (string.IsNullOrWhiteSpace(req.Email) || string.IsNullOrWhiteSpace(req.Password))
                return Results.BadRequest(new { error = "Email and password are required" });

            var result = await auth.LoginAsync(req.Email, req.Password, ctx.RequestAborted);
            if (result.Success)
                return Results.Ok(new { result.AccessToken, result.RefreshToken, result.UserId });

            return result.RequiresConfirmation
                ? Results.Json(
                    new { result.Error, result.RequiresConfirmation, result.Email },
                    statusCode: StatusCodes.Status409Conflict)
                : Results.Json(new { error = "Invalid email or password" }, statusCode: 401);
        }).WithName("Login").RequireRateLimiting("auth");

        group.MapPost("/refresh", async (HttpContext ctx, RefreshRequest req, IAuthService auth) =>
        {
            if (string.IsNullOrWhiteSpace(req.RefreshToken))
                return Results.BadRequest(new { error = "RefreshToken is required" });

            var result = await auth.RefreshAsync(req.RefreshToken, ctx.RequestAborted);
            return result.Success
                ? Results.Ok(new { result.AccessToken, result.RefreshToken, result.UserId })
                : Results.Json(new { error = "Session expired" }, statusCode: 401);
        }).WithName("Refresh").RequireRateLimiting("auth");

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

        group.MapPost("/passkeys/register/start", async (
            HttpContext ctx,
            IPasskeyAuthService passkeys) =>
        {
            var accessToken = ReadBearerToken(ctx.Request.Headers.Authorization.ToString());
            if (accessToken is null || !LooksLikeCognitoToken(accessToken))
            {
                return Results.Json(
                    new { error = "Passkeys are only available for Conscia account sessions." },
                    statusCode: StatusCodes.Status403Forbidden);
            }

            var result = await passkeys.StartRegistrationAsync(accessToken, ctx.RequestAborted);
            return Results.Ok(result);
        }).WithName("StartPasskeyRegistration").RequireAuthorization().RequireRateLimiting("auth");

        group.MapPost("/passkeys/register/complete", async (
            HttpContext ctx,
            CompletePasskeyRegistrationRequest req,
            IPasskeyAuthService passkeys) =>
        {
            var accessToken = ReadBearerToken(ctx.Request.Headers.Authorization.ToString());
            if (accessToken is null || !LooksLikeCognitoToken(accessToken))
            {
                return Results.Json(
                    new { error = "Passkeys are only available for Conscia account sessions." },
                    statusCode: StatusCodes.Status403Forbidden);
            }

            await passkeys.CompleteRegistrationAsync(accessToken, req.Credential, ctx.RequestAborted);
            return Results.NoContent();
        }).WithName("CompletePasskeyRegistration").RequireAuthorization().RequireRateLimiting("auth");

        group.MapPost("/passkeys/login/start", async (
            HttpContext ctx,
            StartPasskeyAuthenticationRequest req,
            IPasskeyAuthService passkeys) =>
        {
            if (string.IsNullOrWhiteSpace(req.Email))
            {
                return Results.BadRequest(new { error = "Email is required" });
            }

            StartPasskeyAuthenticationResponse result;
            try
            {
                result = await passkeys.StartAuthenticationAsync(req.Email, ctx.RequestAborted);
            }
            catch (PasskeyAuthenticationUnavailableException ex)
            {
                return Results.BadRequest(new { error = ex.Message });
            }

            return Results.Ok(result);
        }).WithName("StartPasskeyLogin").RequireRateLimiting("auth");

        group.MapPost("/passkeys/login/complete", async (
            HttpContext ctx,
            CompletePasskeyAuthenticationRequest req,
            IPasskeyAuthService passkeys) =>
        {
            if (string.IsNullOrWhiteSpace(req.Email) ||
                string.IsNullOrWhiteSpace(req.Session) ||
                string.IsNullOrWhiteSpace(req.ChallengeName) ||
                string.IsNullOrWhiteSpace(req.Credential))
            {
                return Results.BadRequest(new { error = "Email, session, challenge, and credential are required" });
            }

            var result = await passkeys.CompleteAuthenticationAsync(
                req.Email,
                req.Session,
                req.ChallengeName,
                req.Credential,
                ctx.RequestAborted);

            return result.Success
                ? Results.Ok(new { result.AccessToken, result.RefreshToken, result.UserId })
                : Results.BadRequest(new { result.Error });
        }).WithName("CompletePasskeyLogin").RequireRateLimiting("auth");

        return group;
    }

    private static string? ReadBearerToken(string authorizationHeader)
    {
        const string bearer = "Bearer ";
        return authorizationHeader.StartsWith(bearer, StringComparison.OrdinalIgnoreCase)
            ? authorizationHeader[bearer.Length..].Trim()
            : null;
    }

    private static bool LooksLikeCognitoToken(string token)
    {
        try
        {
            var jwt = new System.IdentityModel.Tokens.Jwt.JwtSecurityTokenHandler().ReadJwtToken(token);
            return jwt.Issuer.Contains("cognito-idp.", StringComparison.OrdinalIgnoreCase);
        }
        catch
        {
            return false;
        }
    }
}

public record RegisterRequest(string Email, string Password);
public record ConfirmRegistrationRequest(string Email, string ConfirmationCode);
public record ResendConfirmationRequest(string Email);
public record LoginRequest(string Email, string Password);
public record RefreshRequest(string RefreshToken);
public record GoogleLoginRequest(string IdToken);
public record AppleLoginRequest(string IdentityToken, string? AuthorizationCode);
