using Conscia.Application.DTOs;
using Conscia.Application.Interfaces;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Conscia.Domain.ValueObjects;
using Microsoft.Extensions.Logging;

namespace Conscia.Application.Services;

public class RecurringScheduleService : IRecurringScheduleService
{
    private readonly IRecurringScheduleRepository _repo;
    private readonly ILogger<RecurringScheduleService> _logger;
    private readonly IFamilySpaceRepository _familySpaces;

    public RecurringScheduleService(
        IRecurringScheduleRepository repo,
        ILogger<RecurringScheduleService> logger,
        IFamilySpaceRepository familySpaces)
    {
        _repo = repo;
        _logger = logger;
        _familySpaces = familySpaces;
    }

    public async Task<RecurringSchedule> CreateAsync(Guid userId, CreateRecurringScheduleDto dto, CancellationToken ct = default)
    {
        var schedule = new RecurringSchedule
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            Type = dto.Type,
            Amount = new Money(dto.Amount, dto.CurrencyCode),
            Category = dto.Category,
            Counterparty = dto.Counterparty,
            StartDate = dto.StartDate,
            Cadence = dto.Cadence,
            NextRunAt = dto.StartDate,
            EndDate = dto.EndDate,
            IsActive = true,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow,
        };
        await EnsureCanWriteFamilyRecordAsync(userId, dto.Scope, dto.FamilySpaceId, ct);
        ApplyScope(schedule, userId, dto.Scope, dto.FamilySpaceId);

        _logger.LogInformation("Creating recurring schedule {ScheduleId} for user {UserId}", schedule.Id, userId);
        return await _repo.AddAsync(schedule, ct);
    }

    public Task<RecurringSchedule?> GetByIdAsync(Guid userId, Guid id, CancellationToken ct = default) =>
        _repo.GetByIdAsync(userId, id, ct);

    public Task<IReadOnlyList<RecurringSchedule>> ListAsync(Guid userId, CancellationToken ct = default) =>
        _repo.ListAsync(userId, ct);

    public async Task<RecurringSchedule> UpdateAsync(Guid userId, Guid id, UpdateRecurringScheduleDto dto, CancellationToken ct = default)
    {
        var schedule = await _repo.GetByIdAsync(userId, id, ct)
            ?? throw new KeyNotFoundException($"Recurring schedule {id} not found");

        if (dto.Type.HasValue) schedule.Type = dto.Type.Value;
        if (dto.Amount.HasValue)
            schedule.Amount = new Money(dto.Amount.Value, dto.CurrencyCode ?? schedule.Amount.CurrencyCode);
        else if (!string.IsNullOrWhiteSpace(dto.CurrencyCode))
            schedule.Amount = new Money(schedule.Amount.Amount, dto.CurrencyCode!, schedule.Amount.ExchangeRateToBase);

        if (dto.Category is not null) schedule.Category = dto.Category;
        if (dto.Counterparty is not null) schedule.Counterparty = dto.Counterparty;
        if (dto.StartDate.HasValue) schedule.StartDate = dto.StartDate.Value;
        if (dto.Cadence.HasValue) schedule.Cadence = dto.Cadence.Value;
        if (dto.EndDate.HasValue || dto.StartDate.HasValue) schedule.EndDate = dto.EndDate;
        if (dto.IsActive.HasValue) schedule.IsActive = dto.IsActive.Value;
        if (dto.Scope.HasValue)
        {
            await EnsureCanWriteFamilyRecordAsync(userId, dto.Scope.Value, dto.FamilySpaceId, ct);
            ApplyScope(schedule, userId, dto.Scope.Value, dto.FamilySpaceId);
        }

        schedule.UpdatedAt = DateTime.UtcNow;
        await _repo.UpdateAsync(schedule, ct);
        return schedule;
    }

    public Task DeleteAsync(Guid userId, Guid id, CancellationToken ct = default) =>
        _repo.DeleteAsync(userId, id, ct);

    private static void ApplyScope(RecurringSchedule schedule, Guid userId, RecordScope scope, Guid? familySpaceId)
    {
        schedule.Scope = scope;
        if (scope == RecordScope.Family)
        {
            schedule.FamilySpaceId = familySpaceId
                ?? throw new InvalidOperationException("Family Space is required for family recurring schedules.");
            schedule.SharedByUserId = userId;
            schedule.SharedAt ??= DateTime.UtcNow;
            return;
        }

        schedule.FamilySpaceId = null;
        schedule.SharedByUserId = null;
        schedule.SharedAt = null;
    }

    private async Task EnsureCanWriteFamilyRecordAsync(
        Guid userId,
        RecordScope scope,
        Guid? familySpaceId,
        CancellationToken ct)
    {
        if (scope != RecordScope.Family)
            return;

        if (!familySpaceId.HasValue)
            throw new InvalidOperationException("Family Space is required for family recurring schedules.");

        var member = await _familySpaces.GetMembershipByUserIdAsync(userId, ct)
            ?? throw new UnauthorizedAccessException("You do not belong to a Family Space.");

        if (member.FamilySpaceId != familySpaceId.Value)
            throw new UnauthorizedAccessException("You do not belong to that Family Space.");

        if (member.Role == FamilyMemberRole.Viewer)
            throw new UnauthorizedAccessException("Viewer cannot create Family Space records.");
    }
}
