using System.Security.Claims;
using Asp.Versioning.Builder;

namespace Conscia.Api.Endpoints;

public static class ClientDiagnosticEndpoints
{
    private const int MaxContextEntries = 16;
    private const int MaxTextLength = 256;

    public static RouteGroupBuilder MapClientDiagnosticEndpoints(
        this IEndpointRouteBuilder routes,
        ApiVersionSet apiVersionSet)
    {
        var group = routes.MapGroup("/api/client-diagnostics")
            .WithApiVersionSet(apiVersionSet)
            .MapToApiVersion(1.0)
            .RequireAuthorization()
            .WithTags("ClientDiagnostics");

        group.MapPost("/", (
            ClientDiagnosticRequest request,
            HttpContext ctx,
            ILoggerFactory loggerFactory) =>
        {
            if (string.IsNullOrWhiteSpace(request.EventName))
            {
                return Results.BadRequest(new { error = "Event name is required." });
            }

            if (request.Context is { Count: > MaxContextEntries })
            {
                return Results.BadRequest(new { error = "Too many context fields." });
            }

            var appVersion = Clean(
                ctx.Request.Headers["X-Conscia-App-Version"].FirstOrDefault()
                ?? request.AppVersion);
            var level = ToLogLevel(request.Level);
            var userId = ctx.User.FindFirstValue(ClaimTypes.NameIdentifier)
                ?? ctx.User.FindFirstValue("sub");
            var logger = loggerFactory.CreateLogger("Conscia.ClientDiagnostics");

            logger.Log(
                level,
                "Client diagnostic {EventName} {Operation} {Platform} {AppVersion} {UserId} {ErrorType} {ErrorCode} {ErrorMessage} {Context}",
                Clean(request.EventName),
                Clean(request.Operation),
                Clean(request.Platform),
                appVersion,
                Clean(userId),
                Clean(request.ErrorType),
                Clean(request.ErrorCode),
                Clean(request.ErrorMessage),
                CleanContext(request.Context));

            return Results.Accepted();
        }).WithName("ReportClientDiagnostic");

        return group;
    }

    private static LogLevel ToLogLevel(string? level) =>
        level?.Trim().ToLowerInvariant() switch
        {
            "error" => LogLevel.Error,
            "information" or "info" => LogLevel.Information,
            "debug" => LogLevel.Debug,
            _ => LogLevel.Warning
        };

    private static Dictionary<string, string?>? CleanContext(
        IReadOnlyDictionary<string, string?>? context) =>
        context?.ToDictionary(
            entry => Clean(entry.Key) ?? string.Empty,
            entry => Clean(entry.Value));

    private static string? Clean(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return null;
        }

        var trimmed = value.Trim();
        return trimmed.Length <= MaxTextLength
            ? trimmed
            : trimmed[..MaxTextLength];
    }

    public sealed record ClientDiagnosticRequest(
        string? EventName,
        string? Level,
        string? Operation,
        string? Platform,
        string? AppVersion,
        string? ErrorType,
        string? ErrorCode,
        string? ErrorMessage,
        IReadOnlyDictionary<string, string?>? Context);
}
