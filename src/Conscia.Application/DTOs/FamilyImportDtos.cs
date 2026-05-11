namespace Conscia.Application.DTOs;

public record FamilyImportPreviewRequestDto(
    bool IncludeTransactions,
    bool IncludeBudgets,
    bool IncludeRecurringSchedules,
    DateTime? From,
    DateTime? To,
    IReadOnlyList<string> Categories);

public record FamilyImportPreviewDto(
    Guid FamilySpaceId,
    string Warning,
    IReadOnlyList<FamilyImportItemDto> Items);

public record FamilyImportItemDto(
    string RecordType,
    Guid RecordId,
    string Label,
    string? Category,
    decimal? Amount,
    string? CurrencyCode);

public record FamilyImportRequestDto(IReadOnlyList<FamilyImportSelectionDto> Items);

public record FamilyImportSelectionDto(string RecordType, Guid RecordId);
