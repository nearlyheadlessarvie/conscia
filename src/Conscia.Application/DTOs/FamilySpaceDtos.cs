using Conscia.Domain.Enums;

namespace Conscia.Application.DTOs;

public record CreateFamilySpaceDto(string Name, string CurrencyCode);

public record UpdateFamilySpaceDto(string Name);

public record UpdateFamilyMemberRoleDto(FamilyMemberRole Role);

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

public record FamilyMemberDto(
    Guid Id,
    Guid UserId,
    string Email,
    string Role,
    DateTime JoinedAt,
    bool IsCurrentUser);

public record FamilySpaceOverviewDto(
    Guid FamilySpaceId,
    IReadOnlyList<FamilyBudgetOverviewDto> Budgets,
    IReadOnlyList<FamilyActivityDto> RecentActivity,
    IReadOnlyList<FamilyRecurringOverviewDto> RecurringItems);

public record FamilyBudgetOverviewDto(
    Guid Id,
    string Category,
    decimal MonthlyLimit,
    decimal SpentThisMonth,
    int UsagePercent,
    string CurrencyCode);

public record FamilyActivityDto(
    Guid Id,
    string Label,
    string Category,
    string Type,
    decimal Amount,
    string CurrencyCode,
    DateTime Date);

public record FamilyRecurringOverviewDto(
    Guid Id,
    string Label,
    string Category,
    string Type,
    decimal Amount,
    string CurrencyCode,
    string Cadence,
    DateTime NextRunAt);
