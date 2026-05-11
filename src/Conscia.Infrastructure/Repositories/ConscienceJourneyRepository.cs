using System.Globalization;
using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.Model;
using Conscia.Application.Interfaces;
using Conscia.Application.Models;

namespace Conscia.Infrastructure.Repositories;

public class ConscienceJourneyRepository : DynamoRepository, IConscienceJourneyRepository
{
    private const string TableName = "ConscienceJourney";

    public ConscienceJourneyRepository(IAmazonDynamoDB dynamo) : base(dynamo)
    { }

    public async Task<ConscienceJourneyProgress?> GetProgressAsync(Guid userId, CancellationToken ct = default)
    {
        var response = await Dynamo.GetItemAsync(new GetItemRequest
        {
            TableName = TableName,
            Key = Key(DynamoKeys.User(userId), DynamoKeys.ConscienceProgress())
        }, ct);

        return response.Item is null || response.Item.Count == 0
            ? null
            : ProgressFromItem(response.Item);
    }

    public async Task UpsertProgressAsync(ConscienceJourneyProgress progress, CancellationToken ct = default)
    {
        await Dynamo.PutItemAsync(new PutItemRequest
        {
            TableName = TableName,
            Item = ProgressToItem(progress)
        }, ct);
    }

    public async Task<bool> TryInsertEventAsync(ConscienceJourneyEventRecord record, CancellationToken ct = default)
    {
        try
        {
            await Dynamo.PutItemAsync(new PutItemRequest
            {
                TableName = TableName,
                Item = EventToItem(record),
                ConditionExpression = "attribute_not_exists(PK) AND attribute_not_exists(SK)"
            }, ct);

            return true;
        }
        catch (ConditionalCheckFailedException)
        {
            return false;
        }
    }

    public async Task<IReadOnlyList<ConscienceBadgeProgress>> GetBadgeProgressAsync(Guid userId, CancellationToken ct = default)
    {
        var response = await QueryByPrefixAsync(userId, "BADGE#", ct);
        return response.Items.Select(BadgeFromItem).ToList();
    }

    public async Task UpsertBadgeProgressAsync(ConscienceBadgeProgress progress, CancellationToken ct = default)
    {
        await Dynamo.PutItemAsync(new PutItemRequest
        {
            TableName = TableName,
            Item = BadgeToItem(progress)
        }, ct);
    }

    public async Task<IReadOnlyList<ConscienceQuestProgress>> GetQuestProgressAsync(
        Guid userId,
        DateOnly weekStart,
        CancellationToken ct = default)
    {
        var response = await QueryByPrefixAsync(userId, DynamoKeys.ConscienceQuestPrefix(weekStart), ct);
        return response.Items.Select(QuestFromItem).ToList();
    }

    public async Task UpsertQuestProgressAsync(ConscienceQuestProgress progress, CancellationToken ct = default)
    {
        await Dynamo.PutItemAsync(new PutItemRequest
        {
            TableName = TableName,
            Item = QuestToItem(progress)
        }, ct);
    }

    public async Task<ConscienceMascotMoment?> GetRecentMascotMomentAsync(Guid userId, CancellationToken ct = default)
    {
        var response = await Dynamo.QueryAsync(new QueryRequest
        {
            TableName = TableName,
            KeyConditionExpression = "PK = :pk AND begins_with(SK, :prefix)",
            ExpressionAttributeValues = new Dictionary<string, AttributeValue>
            {
                [":pk"] = new(DynamoKeys.User(userId)),
                [":prefix"] = new("MOMENT#")
            },
            ScanIndexForward = false,
            Limit = 1
        }, ct);

        return response.Items.Count == 0 ? null : MascotMomentFromItem(response.Items[0]);
    }

    public async Task AddMascotMomentAsync(ConscienceMascotMoment moment, CancellationToken ct = default)
    {
        await Dynamo.PutItemAsync(new PutItemRequest
        {
            TableName = TableName,
            Item = MascotMomentToItem(moment)
        }, ct);
    }

    private async Task<QueryResponse> QueryByPrefixAsync(Guid userId, string prefix, CancellationToken ct)
    {
        return await Dynamo.QueryAsync(new QueryRequest
        {
            TableName = TableName,
            KeyConditionExpression = "PK = :pk AND begins_with(SK, :prefix)",
            ExpressionAttributeValues = new Dictionary<string, AttributeValue>
            {
                [":pk"] = new(DynamoKeys.User(userId)),
                [":prefix"] = new(prefix)
            }
        }, ct);
    }

    private static Dictionary<string, AttributeValue> ProgressToItem(ConscienceJourneyProgress progress)
    {
        var item = new Dictionary<string, AttributeValue>
        {
            ["PK"] = new(DynamoKeys.User(progress.UserId)),
            ["SK"] = new(DynamoKeys.ConscienceProgress()),
            ["UserId"] = new(progress.UserId.ToString()),
            ["XpTotal"] = Number(progress.XpTotal),
            ["MomentumDays"] = Number(progress.MomentumDays),
            ["BestMomentumDays"] = Number(progress.BestMomentumDays),
            ["UpdatedAt"] = new(progress.UpdatedAt.ToString("O", CultureInfo.InvariantCulture))
        };

        if (progress.LastMomentumDate.HasValue)
            item["LastMomentumDate"] = new(progress.LastMomentumDate.Value.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture));

        return item;
    }

    private static ConscienceJourneyProgress ProgressFromItem(Dictionary<string, AttributeValue> item) =>
        new()
        {
            UserId = Guid.Parse(item["UserId"].S),
            XpTotal = Int(item, "XpTotal"),
            MomentumDays = Int(item, "MomentumDays"),
            BestMomentumDays = Int(item, "BestMomentumDays"),
            LastMomentumDate = item.TryGetValue("LastMomentumDate", out var date)
                ? DateOnly.Parse(date.S, CultureInfo.InvariantCulture)
                : null,
            UpdatedAt = DateTime.Parse(item["UpdatedAt"].S, CultureInfo.InvariantCulture)
        };

    private static Dictionary<string, AttributeValue> EventToItem(ConscienceJourneyEventRecord record) =>
        new()
        {
            ["PK"] = new(DynamoKeys.User(record.UserId)),
            ["SK"] = new(DynamoKeys.ConscienceEvent(record.EventType, record.SourceId)),
            ["UserId"] = new(record.UserId.ToString()),
            ["EventType"] = new(record.EventType),
            ["SourceId"] = new(record.SourceId),
            ["XpAwarded"] = Number(record.XpAwarded),
            ["CreatedAt"] = new(record.CreatedAt.ToString("O", CultureInfo.InvariantCulture))
        };

    private static Dictionary<string, AttributeValue> BadgeToItem(ConscienceBadgeProgress progress)
    {
        var item = new Dictionary<string, AttributeValue>
        {
            ["PK"] = new(DynamoKeys.User(progress.UserId)),
            ["SK"] = new(DynamoKeys.ConscienceBadge(progress.BadgeKey)),
            ["UserId"] = new(progress.UserId.ToString()),
            ["BadgeKey"] = new(progress.BadgeKey),
            ["Progress"] = Number(progress.Progress),
            ["Target"] = Number(progress.Target),
            ["UpdatedAt"] = new(progress.UpdatedAt.ToString("O", CultureInfo.InvariantCulture))
        };

        if (progress.UnlockedAt.HasValue)
            item["UnlockedAt"] = new(progress.UnlockedAt.Value.ToString("O", CultureInfo.InvariantCulture));

        return item;
    }

    private static ConscienceBadgeProgress BadgeFromItem(Dictionary<string, AttributeValue> item) =>
        new()
        {
            UserId = Guid.Parse(item["UserId"].S),
            BadgeKey = item["BadgeKey"].S,
            Progress = Int(item, "Progress"),
            Target = Int(item, "Target"),
            UnlockedAt = item.TryGetValue("UnlockedAt", out var unlockedAt)
                ? DateTime.Parse(unlockedAt.S, CultureInfo.InvariantCulture)
                : null,
            UpdatedAt = DateTime.Parse(item["UpdatedAt"].S, CultureInfo.InvariantCulture)
        };

    private static Dictionary<string, AttributeValue> QuestToItem(ConscienceQuestProgress progress)
    {
        var item = new Dictionary<string, AttributeValue>
        {
            ["PK"] = new(DynamoKeys.User(progress.UserId)),
            ["SK"] = new(DynamoKeys.ConscienceQuest(progress.WeekStart, progress.QuestKey)),
            ["UserId"] = new(progress.UserId.ToString()),
            ["WeekStart"] = new(progress.WeekStart.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture)),
            ["QuestKey"] = new(progress.QuestKey),
            ["Progress"] = Number(progress.Progress),
            ["Target"] = Number(progress.Target),
            ["XpAwarded"] = Number(progress.XpAwarded),
            ["UpdatedAt"] = new(progress.UpdatedAt.ToString("O", CultureInfo.InvariantCulture))
        };

        if (progress.CompletedAt.HasValue)
            item["CompletedAt"] = new(progress.CompletedAt.Value.ToString("O", CultureInfo.InvariantCulture));

        return item;
    }

    private static ConscienceQuestProgress QuestFromItem(Dictionary<string, AttributeValue> item) =>
        new()
        {
            UserId = Guid.Parse(item["UserId"].S),
            WeekStart = DateOnly.Parse(item["WeekStart"].S, CultureInfo.InvariantCulture),
            QuestKey = item["QuestKey"].S,
            Progress = Int(item, "Progress"),
            Target = Int(item, "Target"),
            XpAwarded = Int(item, "XpAwarded"),
            CompletedAt = item.TryGetValue("CompletedAt", out var completedAt)
                ? DateTime.Parse(completedAt.S, CultureInfo.InvariantCulture)
                : null,
            UpdatedAt = DateTime.Parse(item["UpdatedAt"].S, CultureInfo.InvariantCulture)
        };

    private static Dictionary<string, AttributeValue> MascotMomentToItem(ConscienceMascotMoment moment) =>
        new()
        {
            ["PK"] = new(DynamoKeys.User(moment.UserId)),
            ["SK"] = new(DynamoKeys.ConscienceMoment(moment.CreatedAt, moment.Key)),
            ["UserId"] = new(moment.UserId.ToString()),
            ["Key"] = new(moment.Key),
            ["Persona"] = new(moment.Persona),
            ["Title"] = new(moment.Title),
            ["Message"] = new(moment.Message),
            ["CreatedAt"] = new(moment.CreatedAt.ToString("O", CultureInfo.InvariantCulture))
        };

    private static ConscienceMascotMoment MascotMomentFromItem(Dictionary<string, AttributeValue> item) =>
        new()
        {
            UserId = Guid.Parse(item["UserId"].S),
            Key = item["Key"].S,
            Persona = item["Persona"].S,
            Title = item["Title"].S,
            Message = item["Message"].S,
            CreatedAt = DateTime.Parse(item["CreatedAt"].S, CultureInfo.InvariantCulture)
        };

    private static AttributeValue Number(int value) =>
        new() { N = value.ToString(CultureInfo.InvariantCulture) };

    private static int Int(IReadOnlyDictionary<string, AttributeValue> item, string key) =>
        item.TryGetValue(key, out var value) && int.TryParse(value.N, NumberStyles.Integer, CultureInfo.InvariantCulture, out var parsed)
            ? parsed
            : 0;
}
