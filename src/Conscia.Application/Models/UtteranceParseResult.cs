namespace Conscia.Application.Models;

public record UtteranceParseResult(
    string? Description,
    decimal? Amount,
    string? Category
);
