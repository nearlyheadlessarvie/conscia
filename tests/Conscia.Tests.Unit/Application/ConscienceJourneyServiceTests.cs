using Conscia.Application.Constants;
using Conscia.Application.Interfaces;
using Conscia.Application.Models;
using Conscia.Application.Services;

namespace Conscia.Tests.Unit.Application;

public class ConscienceJourneyServiceTests
{
    [Fact]
    public async Task RecordEventAsync_AwardsEventXpAndBuildsSummary()
    {
        var repository = new InMemoryConscienceJourneyRepository();
        var service = new ConscienceJourneyService(repository, new HardcodedJourneyRulesProvider());
        var userId = Guid.NewGuid();

        var result = await service.RecordEventAsync(userId, ConscienceEventTypes.ReflectionCompleted, "tx-1");

        Assert.False(result.WasDuplicate);
        Assert.Equal(20, result.XpAwarded);
        Assert.Equal(20, result.Summary.XpTotal);
        Assert.Equal("awakening", result.Summary.CurrentLevel.Key);
        Assert.Equal("impulse_spotter", result.Summary.NextLevel?.Key);
        Assert.Equal(20, result.Summary.XpIntoLevel);
        Assert.Equal(100, result.Summary.XpToNextLevel);
    }

    [Fact]
    public async Task RecordEventAsync_DuplicateEventDoesNotAwardXpAgain()
    {
        var repository = new InMemoryConscienceJourneyRepository();
        var service = new ConscienceJourneyService(repository, new HardcodedJourneyRulesProvider());
        var userId = Guid.NewGuid();

        await service.RecordEventAsync(userId, ConscienceEventTypes.ReflectionCompleted, "tx-1");
        var duplicate = await service.RecordEventAsync(userId, ConscienceEventTypes.ReflectionCompleted, "tx-1");

        Assert.True(duplicate.WasDuplicate);
        Assert.Equal(0, duplicate.XpAwarded);
        Assert.Equal(20, duplicate.Summary.XpTotal);
        Assert.Single(repository.Events);
    }

    [Fact]
    public async Task RecordEventAsync_CalculatesLevelThresholds()
    {
        var repository = new InMemoryConscienceJourneyRepository();
        var service = new ConscienceJourneyService(repository, new HardcodedJourneyRulesProvider());
        var userId = Guid.NewGuid();

        await repository.UpsertProgressAsync(new ConscienceJourneyProgress
        {
            UserId = userId,
            XpTotal = 95,
            UpdatedAt = DateTime.UtcNow
        });

        var result = await service.RecordEventAsync(userId, ConscienceEventTypes.PrePurchaseChecked, "check-1");

        Assert.True(result.LeveledUp);
        Assert.Equal(125, result.Summary.XpTotal);
        Assert.Equal("impulse_spotter", result.Summary.CurrentLevel.Key);
        Assert.Equal("budget_guardian", result.Summary.NextLevel?.Key);
        Assert.Equal(5, result.Summary.XpIntoLevel);
        Assert.Equal(275, result.Summary.XpToNextLevel);
    }

    [Fact]
    public async Task RecordEventAsync_CompletesWeeklyQuestOnceAndAwardsQuestXp()
    {
        var repository = new InMemoryConscienceJourneyRepository();
        var service = new ConscienceJourneyService(repository, new HardcodedJourneyRulesProvider());
        var userId = Guid.NewGuid();

        var first = await service.RecordEventAsync(userId, ConscienceEventTypes.PrePurchaseChecked, "check-1");
        var second = await service.RecordEventAsync(userId, ConscienceEventTypes.PrePurchaseChecked, "check-2");

        Assert.Equal(30, first.XpAwarded);
        Assert.Contains("check_before_purchase", first.CompletedQuestKeys);
        Assert.Equal(50, second.Summary.XpTotal);
        Assert.Equal(20, second.XpAwarded);
        Assert.DoesNotContain("check_before_purchase", second.CompletedQuestKeys);
    }

    [Fact]
    public async Task RecordEventAsync_UnlocksBadgeAndMascotMoment()
    {
        var repository = new InMemoryConscienceJourneyRepository();
        var service = new ConscienceJourneyService(repository, new HardcodedJourneyRulesProvider());
        var userId = Guid.NewGuid();

        var result = await service.RecordEventAsync(userId, ConscienceEventTypes.RegretPatternReviewed, "pattern-1");

        Assert.Contains("regret_pattern_spotted", result.UnlockedBadgeKeys);
        Assert.Contains(result.Summary.Badges, b => b.Key == "regret_pattern_spotted" && b.IsUnlocked);
        Assert.NotNull(result.MascotMoment);
        Assert.Equal("regret_pattern_spotted", result.MascotMoment!.Key);
        Assert.Equal("devil", result.MascotMoment.Persona);
    }

    [Fact]
    public async Task RecordEventAsync_MomentumDoesNotResetAfterMissedDays()
    {
        var repository = new InMemoryConscienceJourneyRepository();
        var service = new ConscienceJourneyService(repository, new HardcodedJourneyRulesProvider());
        var userId = Guid.NewGuid();

        await repository.UpsertProgressAsync(new ConscienceJourneyProgress
        {
            UserId = userId,
            XpTotal = 100,
            MomentumDays = 4,
            BestMomentumDays = 7,
            LastMomentumDate = DateOnly.FromDateTime(DateTime.UtcNow.Date.AddDays(-5)),
            UpdatedAt = DateTime.UtcNow.AddDays(-5)
        });

        var result = await service.RecordEventAsync(userId, ConscienceEventTypes.InsightReviewed, "insight-1");

        Assert.Equal(5, result.Summary.MomentumDays);
        Assert.Equal(7, result.Summary.BestMomentumDays);
    }

    private sealed class InMemoryConscienceJourneyRepository : IConscienceJourneyRepository
    {
        private readonly Dictionary<Guid, ConscienceJourneyProgress> _progress = [];
        private readonly HashSet<string> _eventKeys = [];
        private readonly Dictionary<Guid, List<ConscienceBadgeProgress>> _badges = [];
        private readonly Dictionary<Guid, List<ConscienceQuestProgress>> _quests = [];
        private readonly Dictionary<Guid, List<ConscienceMascotMoment>> _moments = [];

        public List<ConscienceJourneyEventRecord> Events { get; } = [];

        public Task<ConscienceJourneyProgress?> GetProgressAsync(Guid userId, CancellationToken ct = default) =>
            Task.FromResult(_progress.GetValueOrDefault(userId));

        public Task UpsertProgressAsync(ConscienceJourneyProgress progress, CancellationToken ct = default)
        {
            _progress[progress.UserId] = progress;
            return Task.CompletedTask;
        }

        public Task<bool> TryInsertEventAsync(ConscienceJourneyEventRecord record, CancellationToken ct = default)
        {
            var key = $"{record.UserId}:{record.EventType}:{record.SourceId}";
            if (!_eventKeys.Add(key))
                return Task.FromResult(false);

            Events.Add(record);
            return Task.FromResult(true);
        }

        public Task<IReadOnlyList<ConscienceJourneyEventRecord>> ListEventsAsync(
            Guid userId,
            int limit = 1000,
            CancellationToken ct = default)
        {
            var events = Events
                .Where(x => x.UserId == userId)
                .Take(limit)
                .ToList();
            return Task.FromResult((IReadOnlyList<ConscienceJourneyEventRecord>)events);
        }

        public Task<IReadOnlyList<ConscienceBadgeProgress>> GetBadgeProgressAsync(Guid userId, CancellationToken ct = default) =>
            Task.FromResult((IReadOnlyList<ConscienceBadgeProgress>)_badges.GetValueOrDefault(userId, []));

        public Task UpsertBadgeProgressAsync(ConscienceBadgeProgress progress, CancellationToken ct = default)
        {
            var items = _badges.GetValueOrDefault(progress.UserId) ?? [];
            items.RemoveAll(x => x.BadgeKey == progress.BadgeKey);
            items.Add(progress);
            _badges[progress.UserId] = items;
            return Task.CompletedTask;
        }

        public Task<IReadOnlyList<ConscienceQuestProgress>> GetQuestProgressAsync(
            Guid userId,
            DateOnly weekStart,
            CancellationToken ct = default)
        {
            var quests = _quests.GetValueOrDefault(userId, [])
                .Where(x => x.WeekStart == weekStart)
                .ToList();
            return Task.FromResult((IReadOnlyList<ConscienceQuestProgress>)quests);
        }

        public Task<IReadOnlyList<ConscienceQuestProgress>> ListQuestProgressAsync(
            Guid userId,
            int limit = 1000,
            CancellationToken ct = default)
        {
            var quests = _quests.GetValueOrDefault(userId, [])
                .Take(limit)
                .ToList();
            return Task.FromResult((IReadOnlyList<ConscienceQuestProgress>)quests);
        }

        public Task UpsertQuestProgressAsync(ConscienceQuestProgress progress, CancellationToken ct = default)
        {
            var items = _quests.GetValueOrDefault(progress.UserId) ?? [];
            items.RemoveAll(x => x.WeekStart == progress.WeekStart && x.QuestKey == progress.QuestKey);
            items.Add(progress);
            _quests[progress.UserId] = items;
            return Task.CompletedTask;
        }

        public Task<ConscienceMascotMoment?> GetRecentMascotMomentAsync(Guid userId, CancellationToken ct = default)
        {
            var moment = _moments.GetValueOrDefault(userId, [])
                .OrderByDescending(x => x.CreatedAt)
                .FirstOrDefault();
            return Task.FromResult(moment);
        }

        public Task<IReadOnlyList<ConscienceMascotMoment>> ListMascotMomentsAsync(
            Guid userId,
            int limit = 100,
            CancellationToken ct = default)
        {
            var moments = _moments.GetValueOrDefault(userId, [])
                .OrderByDescending(x => x.CreatedAt)
                .Take(limit)
                .ToList();
            return Task.FromResult((IReadOnlyList<ConscienceMascotMoment>)moments);
        }

        public Task AddMascotMomentAsync(ConscienceMascotMoment moment, CancellationToken ct = default)
        {
            var items = _moments.GetValueOrDefault(moment.UserId) ?? [];
            items.Add(moment);
            _moments[moment.UserId] = items;
            return Task.CompletedTask;
        }
    }
}
