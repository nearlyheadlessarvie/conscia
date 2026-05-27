using Conscia.Api.Models;
using Microsoft.AspNetCore.Diagnostics;

namespace Conscia.Api.Middleware;

public class GlobalExceptionHandler : IExceptionHandler
{
    private readonly ILogger<GlobalExceptionHandler> _logger;
    private readonly IHostEnvironment _environment;

    public GlobalExceptionHandler(ILogger<GlobalExceptionHandler> logger, IHostEnvironment environment)
    {
        _logger = logger;
        _environment = environment;
    }

    public async ValueTask<bool> TryHandleAsync(HttpContext context, Exception exception, CancellationToken ct)
    {
        var correlationId = CorrelationIdMiddleware.GetCorrelationId(context);
        var (statusCode, error) = exception switch
        {
            KeyNotFoundException e => (404, new ErrorResponse(e.Message)),
            UnauthorizedAccessException e => (403, new ErrorResponse(e.Message)),
            FluentValidation.ValidationException e => (400, new ErrorResponse("Validation failed",
                e.Errors.Select(err => new { err.PropertyName, err.ErrorMessage }))),
            ArgumentException e => (400, new ErrorResponse(e.Message)),
            InvalidOperationException e => (409, new ErrorResponse(e.Message)),
            _ => (500, new ErrorResponse("An unexpected error occurred"))
        };

        error = error with { CorrelationId = correlationId };

        _logger.LogError(
            exception,
            "Unhandled exception {CorrelationId}: {StatusCode} {ErrorMessage}",
            correlationId,
            statusCode,
            error.Error);

        if (_environment.IsDevelopment() && error.Details is null)
        {
            error = error with { Details = exception.ToString() };
        }

        context.Response.StatusCode = statusCode;
        await context.Response.WriteAsJsonAsync(error, ct);
        return true;
    }
}
