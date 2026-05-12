using Conscia.Domain.Enums;

namespace Conscia.Application.DTOs;

public record CategoryDto(
    Guid Id,
    string Name,
    string NormalizedName,
    string Type,
    string Scope,
    Guid? FamilySpaceId,
    string IconKey,
    string ColorKey,
    bool IsArchived,
    bool IsDefault,
    DateTime CreatedAt,
    DateTime UpdatedAt);

public record CreateCategoryDto(
    string Name,
    TransactionType Type,
    RecordScope Scope,
    Guid? FamilySpaceId,
    string IconKey,
    string ColorKey);

public record UpdateCategoryDto(
    string? Name,
    string? IconKey,
    string? ColorKey,
    bool? IsArchived);
