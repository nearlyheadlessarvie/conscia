namespace Conscia.Api.Models;

public sealed record ErrorResponse(string Error, object? Details = null);
