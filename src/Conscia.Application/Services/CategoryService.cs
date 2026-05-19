using System.Text.RegularExpressions;
using Conscia.Application.DTOs;
using Conscia.Application.Interfaces;
using Conscia.Domain.Constants;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Microsoft.Extensions.Logging;

namespace Conscia.Application.Services;

public partial class CategoryService : ICategoryService
{
    private readonly ICategoryRepository _categories;
    private readonly IFamilySpaceRepository _familySpaces;
    private readonly ILogger<CategoryService> _logger;

    public CategoryService(
        ICategoryRepository categories,
        IFamilySpaceRepository familySpaces,
        ILogger<CategoryService> logger)
    {
        _categories = categories;
        _familySpaces = familySpaces;
        _logger = logger;
    }

    public async Task<IReadOnlyList<CategoryDto>> ListAsync(
        Guid userId,
        RecordScope scope = RecordScope.Personal,
        Guid? familySpaceId = null,
        bool includeArchived = false,
        CancellationToken ct = default)
    {
        var categories = scope == RecordScope.Family
            ? await ListFamilyAsync(userId, familySpaceId, ct)
            : await _categories.ListPersonalAsync(userId, ct);

        if (scope == RecordScope.Personal && categories.Count == 0)
        {
            categories = await SeedDefaultsAsync(userId, RecordScope.Personal, null, ct);
        }

        return categories
            .Where(c => includeArchived || !c.IsArchived)
            .OrderBy(c => c.Type)
            .ThenBy(c => c.Name)
            .Select(ToDto)
            .ToList();
    }

    public async Task<CategoryDto> CreateAsync(Guid userId, CreateCategoryDto dto, CancellationToken ct = default)
    {
        var name = CleanName(dto.Name);
        var normalized = NormalizeName(name);
        var familySpaceId = await ResolveWritableFamilySpaceAsync(userId, dto.Scope, dto.FamilySpaceId, ct);
        await EnsureUniqueAsync(userId, familySpaceId, dto.Scope, dto.Type, normalized, null, ct);

        var category = new ManagedCategory
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            Name = name,
            NormalizedName = normalized,
            Type = dto.Type,
            Scope = dto.Scope,
            FamilySpaceId = familySpaceId,
            IconKey = CleanOptional(dto.IconKey, DefaultIconKey(name)),
            ColorKey = CleanOptional(dto.ColorKey, DefaultColorKey(name, dto.Type)),
            IsDefault = false,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        var result = await _categories.AddAsync(category, ct);
        _logger.LogInformation("Created managed category {CategoryId} for user {UserId}", result.Id, userId);
        return ToDto(result);
    }

    public async Task<CategoryDto> UpdateAsync(Guid userId, Guid id, UpdateCategoryDto dto, CancellationToken ct = default)
    {
        var category = await RequireOwnedCategoryAsync(userId, id, requireFamilyOwner: true, ct);

        if (!string.IsNullOrWhiteSpace(dto.Name))
        {
            var name = CleanName(dto.Name);
            var normalized = NormalizeName(name);
            if (!string.Equals(normalized, category.NormalizedName, StringComparison.Ordinal))
            {
                await EnsureUniqueAsync(
                    category.UserId,
                    category.FamilySpaceId,
                    category.Scope,
                    category.Type,
                    normalized,
                    category.Id,
                    ct);
            }
            category.Name = name;
            category.NormalizedName = normalized;
        }

        if (!string.IsNullOrWhiteSpace(dto.IconKey))
            category.IconKey = CleanOptional(dto.IconKey, "other");
        if (!string.IsNullOrWhiteSpace(dto.ColorKey))
            category.ColorKey = CleanOptional(dto.ColorKey, "blue");
        if (dto.IsArchived.HasValue)
            category.IsArchived = dto.IsArchived.Value;

        category.UpdatedAt = DateTime.UtcNow;
        var result = await _categories.UpdateAsync(category, ct);
        return ToDto(result);
    }

    public async Task ArchiveAsync(Guid userId, Guid id, CancellationToken ct = default)
    {
        var category = await RequireOwnedCategoryAsync(userId, id, requireFamilyOwner: true, ct);
        category.IsArchived = true;
        category.UpdatedAt = DateTime.UtcNow;
        await _categories.UpdateAsync(category, ct);
    }

    private async Task<IReadOnlyList<ManagedCategory>> ListFamilyAsync(
        Guid userId,
        Guid? requestedFamilySpaceId,
        CancellationToken ct)
    {
        var member = await _familySpaces.GetMembershipByUserIdAsync(userId, ct)
            ?? throw new UnauthorizedAccessException("You do not belong to a Family Space.");

        if (requestedFamilySpaceId.HasValue && requestedFamilySpaceId.Value != member.FamilySpaceId)
            throw new UnauthorizedAccessException("You do not belong to that Family Space.");

        var categories = await _categories.ListByFamilySpaceAsync(member.FamilySpaceId, ct);
        return categories.Count == 0
            ? await SeedDefaultsAsync(userId, RecordScope.Family, member.FamilySpaceId, ct)
            : categories;
    }

    private async Task<Guid?> ResolveWritableFamilySpaceAsync(
        Guid userId,
        RecordScope scope,
        Guid? requestedFamilySpaceId,
        CancellationToken ct)
    {
        if (scope == RecordScope.Personal)
            return null;

        var member = await _familySpaces.GetMembershipByUserIdAsync(userId, ct)
            ?? throw new UnauthorizedAccessException("You do not belong to a Family Space.");

        if (requestedFamilySpaceId.HasValue && requestedFamilySpaceId.Value != member.FamilySpaceId)
            throw new UnauthorizedAccessException("You do not belong to that Family Space.");

        if (member.Role != FamilyMemberRole.Owner)
            throw new UnauthorizedAccessException("Only Family Space owners can manage shared categories.");

        return member.FamilySpaceId;
    }

    private async Task<ManagedCategory> RequireOwnedCategoryAsync(
        Guid userId,
        Guid id,
        bool requireFamilyOwner,
        CancellationToken ct)
    {
        var category = await _categories.GetByIdAsync(id, ct)
            ?? throw new KeyNotFoundException("Category was not found.");

        if (category.Scope == RecordScope.Personal)
        {
            if (category.UserId != userId)
                throw new UnauthorizedAccessException("Category does not belong to this user.");
            return category;
        }

        var member = await _familySpaces.GetMembershipByUserIdAsync(userId, ct)
            ?? throw new UnauthorizedAccessException("You do not belong to a Family Space.");
        if (member.FamilySpaceId != category.FamilySpaceId)
            throw new UnauthorizedAccessException("You do not belong to that Family Space.");
        if (requireFamilyOwner && member.Role != FamilyMemberRole.Owner)
            throw new UnauthorizedAccessException("Only Family Space owners can manage shared categories.");

        return category;
    }

    private async Task<IReadOnlyList<ManagedCategory>> SeedDefaultsAsync(
        Guid userId,
        RecordScope scope,
        Guid? familySpaceId,
        CancellationToken ct)
    {
        var defaults = TransactionCategories.Expense
            .Select(name => CreateDefault(userId, scope, familySpaceId, name, TransactionType.Expense))
            .Concat(TransactionCategories.Income.Select(name => CreateDefault(userId, scope, familySpaceId, name, TransactionType.Income)))
            .ToList();

        var results = new List<ManagedCategory>(defaults.Count);
        foreach (var category in defaults)
        {
            results.Add(await _categories.AddAsync(category, ct));
        }

        return results;
    }

    private static ManagedCategory CreateDefault(
        Guid userId,
        RecordScope scope,
        Guid? familySpaceId,
        string name,
        TransactionType type) => new()
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            Name = name,
            NormalizedName = NormalizeName(name),
            Type = type,
            Scope = scope,
            FamilySpaceId = familySpaceId,
            IconKey = DefaultIconKey(name),
            ColorKey = DefaultColorKey(name, type),
            IsDefault = true,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

    private async Task EnsureUniqueAsync(
        Guid userId,
        Guid? familySpaceId,
        RecordScope scope,
        TransactionType type,
        string normalizedName,
        Guid? currentId,
        CancellationToken ct)
    {
        var existing = await _categories.GetByNormalizedNameAsync(userId, familySpaceId, scope, type, normalizedName, ct);
        if (existing is not null && existing.Id != currentId)
            throw new InvalidOperationException("A category with that name already exists.");
    }

    private static CategoryDto ToDto(ManagedCategory category) => new(
        category.Id,
        category.Name,
        category.NormalizedName,
        category.Type.ToString(),
        category.Scope.ToString(),
        category.FamilySpaceId,
        category.IconKey,
        category.ColorKey,
        category.IsArchived,
        category.IsDefault,
        category.CreatedAt,
        category.UpdatedAt);

    private static string CleanName(string name)
    {
        var cleaned = name.Trim();
        if (string.IsNullOrWhiteSpace(cleaned))
            throw new InvalidOperationException("Category name is required.");
        if (cleaned.Length > 100)
            throw new InvalidOperationException("Category name must be 100 characters or fewer.");
        return cleaned;
    }

    private static string CleanOptional(string? value, string fallback)
    {
        var cleaned = value?.Trim() ?? string.Empty;
        return string.IsNullOrWhiteSpace(cleaned) ? fallback : cleaned[..Math.Min(cleaned.Length, 40)];
    }

    private static string DefaultIconKey(string name)
    {
        var normalized = NormalizeName(name);
        return KnownIconKeys.Contains(normalized) ? normalized : "other";
    }

    private static readonly HashSet<string> KnownIconKeys = new(StringComparer.Ordinal)
    {
        "groceries",
        "dining",
        "transport",
        "entertainment",
        "gaming",
        "shopping",
        "health",
        "bills",
        "education",
        "travel",
        "coffee",
        "subscriptions",
        "salary",
        "freelance",
        "business",
        "investment",
        "rental-income",
        "bonus",
        "gift",
        "other"
    };

    private static string DefaultColorKey(string name, TransactionType type)
    {
        var normalized = NormalizeName(name);
        return normalized switch
        {
            "dining" => "green",
            "groceries" => "orange",
            "bills" => "pink",
            "shopping" => "blue",
            "transport" => "cyan",
            "entertainment" => "violet",
            "education" => "blue",
            "coffee" => "orange",
            "gift" => "pink",
            "travel" => "cyan",
            "gaming" => "violet",
            "health" => "pink",
            "subscriptions" => "blue",
            "salary" => "teal",
            "freelance" => "orange",
            "business" => "violet",
            "investment" => "green",
            "rental-income" => "cyan",
            "bonus" => "amber",
            "other" => type == TransactionType.Income ? "teal" : "cyan",
            _ => DeterministicColorKey(normalized, type)
        };
    }

    private static string DeterministicColorKey(string normalized, TransactionType type)
    {
        var palette = type == TransactionType.Income
            ? new[] { "teal", "green", "amber", "cyan", "violet" }
            : new[] { "green", "orange", "pink", "blue", "cyan", "violet" };
        var sum = normalized.Aggregate(0, (current, ch) => current + ch);
        return palette[Math.Abs(sum) % palette.Length];
    }

    private static string NormalizeName(string name) =>
        SlugPattern().Replace(name.Trim().ToLowerInvariant(), "-").Trim('-');

    [GeneratedRegex("[^a-z0-9]+")]
    private static partial Regex SlugPattern();
}
