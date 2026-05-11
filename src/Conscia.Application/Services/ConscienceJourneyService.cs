using Conscia.Application.Constants;
using Conscia.Application.DTOs;
using Conscia.Application.Interfaces;
using Conscia.Application.Models;

namespace Conscia.Application.Services;

public class ConscienceJourneyService : IConscienceJourneyService
{
    private readonly IConscienceJourneyRepository _repository;

    public ConscienceJourneyService(IConscienceJourneyRepository repository)
    {
        _repository = repository;
    }

    public async Task<ConscienceJourneySummaryDto> GetJourneyAsync(Guid userId, CancellationToken ct = default)
    {
        var progress = await GetOrCreateProgressAsync(userId, ct);
        return await BuildSummaryAsync(progress, ct);
    }

    public async Task<ConscienceJourneyUpdateDto> RecordEventAsync(
        Guid userId,
        string eventType,
        string sourceId,
        CancellationToken ct = default)
    {
        if (!ConscienceJourneyRules.XpByEventType.TryGetValue(eventType, out var eventXp))
            throw new ArgumentException($"Unsupported conscience journey event type '{eventType}'.", nameof(eventType));

        if (string.IsNullOrWhiteSpace(sourceId))
            throw new ArgumentException("A source id is required for idempotent journey events.", nameof(sourceId));

        var now = DateTime.UtcNow;
        var progress = await GetOrCreateProgressAsync(userId, ct);
        var previousLevel = CalculateLevel(progress.XpTotal).Current;

        var inserted = await _repository.TryInsertEventAsync(new ConscienceJourneyEventRecord
        {
            UserId = userId,
            EventType = eventType,
            SourceId = sourceId.Trim(),
            XpAwarded = eventXp,
            CreatedAt = now
        }, ct);

        if (!inserted)
        {
            var duplicateSummary = await BuildSummaryAsync(progress, ct);
            return new ConscienceJourneyUpdateDto(
                duplicateSummary,
                XpAwarded: 0,
                WasDuplicate: true,
                LeveledUp: false,
                CompletedQuestKeys: [],
                UnlockedBadgeKeys: [],
                MascotMoment: null);
        }

        var xpAwarded = eventXp;
        var completedQuestKeys = new List<string>();
        var unlockedBadgeKeys = new List<string>();

        progress.XpTotal += eventXp;
        ApplyMomentum(progress, now);

        xpAwarded += await ApplyQuestProgressAsync(userId, eventType, now, completedQuestKeys, ct);
        progress.XpTotal += xpAwarded - eventXp;

        var mascotMoment = await ApplyBadgeProgressAsync(userId, eventType, now, unlockedBadgeKeys, ct);
        progress.UpdatedAt = now;
        await _repository.UpsertProgressAsync(progress, ct);

        if (mascotMoment is not null)
            await _repository.AddMascotMomentAsync(ToModel(userId, mascotMoment), ct);

        var summary = await BuildSummaryAsync(progress, ct);
        var currentLevel = CalculateLevel(summary.XpTotal).Current;

        return new ConscienceJourneyUpdateDto(
            summary,
            xpAwarded,
            WasDuplicate: false,
            LeveledUp: !string.Equals(previousLevel.Key, currentLevel.Key, StringComparison.Ordinal),
            CompletedQuestKeys: completedQuestKeys,
            UnlockedBadgeKeys: unlockedBadgeKeys,
            MascotMoment: mascotMoment);
    }

    private async Task<ConscienceJourneyProgress> GetOrCreateProgressAsync(Guid userId, CancellationToken ct)
    {
        return await _repository.GetProgressAsync(userId, ct)
            ?? new ConscienceJourneyProgress
            {
                UserId = userId,
                UpdatedAt = DateTime.UtcNow
            };
    }

    private async Task<int> ApplyQuestProgressAsync(
        Guid userId,
        string eventType,
        DateTime now,
        ICollection<string> completedQuestKeys,
        CancellationToken ct)
    {
        var matchingRules = ConscienceJourneyRules.WeeklyQuests
            .Where(q => string.Equals(q.EventType, eventType, StringComparison.Ordinal))
            .ToList();

        if (matchingRules.Count == 0)
            return 0;

        var weekStart = CurrentWeekStart(now);
        var existing = (await _repository.GetQuestProgressAsync(userId, weekStart, ct))
            .ToDictionary(q => q.QuestKey, StringComparer.Ordinal);

        var xpAwarded = 0;

        foreach (var rule in matchingRules)
        {
            existing.TryGetValue(rule.Key, out var progress);
            progress ??= new ConscienceQuestProgress
            {
                UserId = userId,
                WeekStart = weekStart,
                QuestKey = rule.Key,
                Target = rule.Target
            };

            progress.Target = rule.Target;
            progress.UpdatedAt = now;

            if (progress.CompletedAt is null)
            {
                progress.Progress = Math.Min(rule.Target, progress.Progress + 1);

                if (progress.Progress >= rule.Target)
                {
                    progress.CompletedAt = now;
                    progress.XpAwarded = rule.XpReward;
                    xpAwarded += rule.XpReward;
                    completedQuestKeys.Add(rule.Key);
                }
            }

            await _repository.UpsertQuestProgressAsync(progress, ct);
        }

        return xpAwarded;
    }

    private async Task<ConscienceMascotMomentDto?> ApplyBadgeProgressAsync(
        Guid userId,
        string eventType,
        DateTime now,
        ICollection<string> unlockedBadgeKeys,
        CancellationToken ct)
    {
        var matchingRules = ConscienceJourneyRules.Badges
            .Where(b => string.Equals(b.EventType, eventType, StringComparison.Ordinal))
            .ToList();

        if (matchingRules.Count == 0)
            return null;

        var existing = (await _repository.GetBadgeProgressAsync(userId, ct))
            .ToDictionary(b => b.BadgeKey, StringComparer.Ordinal);
        ConscienceMascotMomentDto? mascotMoment = null;

        foreach (var rule in matchingRules)
        {
            existing.TryGetValue(rule.Key, out var progress);
            progress ??= new ConscienceBadgeProgress
            {
                UserId = userId,
                BadgeKey = rule.Key,
                Target = rule.Target
            };

            progress.Target = rule.Target;
            progress.UpdatedAt = now;

            if (progress.UnlockedAt is null)
            {
                progress.Progress = Math.Min(rule.Target, progress.Progress + 1);

                if (progress.Progress >= rule.Target)
                {
                    progress.UnlockedAt = now;
                    unlockedBadgeKeys.Add(rule.Key);
                    mascotMoment ??= BuildMascotMoment(rule.Key, now);
                }
            }

            await _repository.UpsertBadgeProgressAsync(progress, ct);
        }

        return mascotMoment;
    }

    private async Task<ConscienceJourneySummaryDto> BuildSummaryAsync(
        ConscienceJourneyProgress progress,
        CancellationToken ct)
    {
        var weekStart = CurrentWeekStart(DateTime.UtcNow);
        var quests = await _repository.GetQuestProgressAsync(progress.UserId, weekStart, ct);
        var badges = await _repository.GetBadgeProgressAsync(progress.UserId, ct);
        var recentMoment = await _repository.GetRecentMascotMomentAsync(progress.UserId, ct);
        var level = CalculateLevel(progress.XpTotal);

        return new ConscienceJourneySummaryDto(
            progress.XpTotal,
            ToDto(level.Current),
            level.Next is null ? null : ToDto(level.Next),
            XpIntoLevel: progress.XpTotal - level.Current.RequiredXp,
            XpToNextLevel: level.Next is null ? 0 : level.Next.RequiredXp - progress.XpTotal,
            progress.MomentumDays,
            progress.BestMomentumDays,
            BuildQuestDtos(quests),
            BuildBadgeDtos(badges),
            recentMoment is null ? null : ToDto(recentMoment));
    }

    private static IReadOnlyList<ConscienceQuestDto> BuildQuestDtos(IReadOnlyList<ConscienceQuestProgress> progress)
    {
        var byKey = progress.ToDictionary(q => q.QuestKey, StringComparer.Ordinal);

        return ConscienceJourneyRules.WeeklyQuests
            .Select(rule =>
            {
                byKey.TryGetValue(rule.Key, out var item);
                var value = item?.Progress ?? 0;
                var completedAt = item?.CompletedAt;

                return new ConscienceQuestDto(
                    rule.Key,
                    rule.Title,
                    rule.Description,
                    value,
                    rule.Target,
                    rule.XpReward,
                    completedAt.HasValue || value >= rule.Target,
                    completedAt);
            })
            .ToList();
    }

    private static IReadOnlyList<ConscienceBadgeDto> BuildBadgeDtos(IReadOnlyList<ConscienceBadgeProgress> progress)
    {
        var byKey = progress.ToDictionary(b => b.BadgeKey, StringComparer.Ordinal);

        return ConscienceJourneyRules.Badges
            .Select(rule =>
            {
                byKey.TryGetValue(rule.Key, out var item);
                var value = item?.Progress ?? 0;
                var unlockedAt = item?.UnlockedAt;

                return new ConscienceBadgeDto(
                    rule.Key,
                    rule.Title,
                    rule.Description,
                    value,
                    rule.Target,
                    unlockedAt.HasValue || value >= rule.Target,
                    unlockedAt);
            })
            .ToList();
    }

    private static void ApplyMomentum(ConscienceJourneyProgress progress, DateTime now)
    {
        var today = DateOnly.FromDateTime(now.Date);
        if (progress.LastMomentumDate != today)
        {
            progress.MomentumDays += 1;
            progress.BestMomentumDays = Math.Max(progress.BestMomentumDays, progress.MomentumDays);
            progress.LastMomentumDate = today;
        }
    }

    private static (ConscienceLevelRule Current, ConscienceLevelRule? Next) CalculateLevel(int xp)
    {
        var current = ConscienceJourneyRules.Levels.Last(l => xp >= l.RequiredXp);
        var next = ConscienceJourneyRules.Levels.FirstOrDefault(l => l.RequiredXp > xp);
        return (current, next);
    }

    private static DateOnly CurrentWeekStart(DateTime now)
    {
        var start = now.Date.AddDays(-(int)now.DayOfWeek);
        return DateOnly.FromDateTime(start);
    }

    private static ConscienceMascotMomentDto? BuildMascotMoment(string key, DateTime now)
    {
        var rule = ConscienceJourneyRules.MascotMoments.FirstOrDefault(m =>
            string.Equals(m.Key, key, StringComparison.Ordinal));

        return rule is null
            ? null
            : new ConscienceMascotMomentDto(rule.Key, rule.Persona, rule.Title, rule.Message, now);
    }

    private static ConscienceMascotMoment ToModel(Guid userId, ConscienceMascotMomentDto dto) =>
        new()
        {
            UserId = userId,
            Key = dto.Key,
            Persona = dto.Persona,
            Title = dto.Title,
            Message = dto.Message,
            CreatedAt = dto.CreatedAt
        };

    private static ConscienceLevelDto ToDto(ConscienceLevelRule rule) =>
        new(rule.Key, rule.Title, rule.RequiredXp);

    private static ConscienceMascotMomentDto ToDto(ConscienceMascotMoment moment) =>
        new(moment.Key, moment.Persona, moment.Title, moment.Message, moment.CreatedAt);
}
