using Conscia.Domain.Enums;

namespace Conscia.Application.DTOs;

public record CreateFamilySpaceDto(string Name, string CurrencyCode);

public record FamilySpaceDto(
    Guid Id,
    string Name,
    string CurrencyCode,
    bool IsReadOnly,
    string Role);

public record CreateFamilyInviteDto(string Email, FamilyMemberRole Role);

public record FamilyInviteDto(
    Guid Id,
    Guid FamilySpaceId,
    string FamilySpaceName,
    string Email,
    string Role,
    DateTime CreatedAt,
    DateTime ExpiresAt);
