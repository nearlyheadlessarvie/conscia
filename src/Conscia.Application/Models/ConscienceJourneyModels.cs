namespace Conscia.Application.Models;

public class ConscienceJourneyProgress
{
    public Guid UserId { get; set; }
    public int XpTotal { get; set; }
    public int MomentumDays { get; set; }
    public int BestMomentumDays { get; set; }
    public DateOnly? LastMomentumDate { get; set; }
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}

public class ConscienceJourneyEventRecord
{
    public Guid UserId { get; set; }
    public string EventType { get; set; } = string.Empty;
    public string SourceId { get; set; } = string.Empty;
    public int XpAwarded { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

public class ConscienceBadgeProgress
{
    public Guid UserId { get; set; }
    public string BadgeKey { get; set; } = string.Empty;
    public int Progress { get; set; }
    public int Target { get; set; }
    public DateTime? UnlockedAt { get; set; }
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}

public class ConscienceQuestProgress
{
    public Guid UserId { get; set; }
    public DateOnly WeekStart { get; set; }
    public string QuestKey { get; set; } = string.Empty;
    public int Progress { get; set; }
    public int Target { get; set; }
    public int XpAwarded { get; set; }
    public DateTime? CompletedAt { get; set; }
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}

public class ConscienceMascotMoment
{
    public Guid UserId { get; set; }
    public string Key { get; set; } = string.Empty;
    public string Persona { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
