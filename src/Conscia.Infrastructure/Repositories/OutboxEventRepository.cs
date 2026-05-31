using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.Model;
using Conscia.Application.Interfaces;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;

namespace Conscia.Infrastructure.Repositories;

public class OutboxEventRepository : DynamoRepository, IOutboxEventRepository
{
    private const string TableName = "OutboxEvents";
    private const string PendingStatus = "PENDING";
    private const string ProcessingStatus = "PROCESSING";
    private static readonly TimeSpan ProcessingLease = TimeSpan.FromMinutes(15);

    public OutboxEventRepository(IAmazonDynamoDB dynamo) : base(dynamo)
    {}

    public async Task<OutboxEvent> AddAsync(OutboxEvent outboxEvent, CancellationToken ct = default)
    {
        await Dynamo.PutItemAsync(new PutItemRequest
        {
            TableName = TableName,
            Item = ToItem(outboxEvent)
        }, ct);

        return outboxEvent;
    }

    public async Task<IReadOnlyList<OutboxEvent>> GetPendingAsync(int limit = 50, CancellationToken ct = default)
    {
        var pending = await QueryByStatusAsync(PendingStatus, limit, ct);
        if (pending.Count >= limit)
            return pending;

        var staleProcessing = await QueryByStatusAsync(
            ProcessingStatus,
            limit - pending.Count,
            ct,
            DateTime.UtcNow.Subtract(ProcessingLease));

        return pending.Concat(staleProcessing).ToList();
    }

    private async Task<IReadOnlyList<OutboxEvent>> QueryByStatusAsync(
        string status,
        int limit,
        CancellationToken ct,
        DateTime? processingStartedBefore = null)
    {
        if (limit <= 0)
            return [];

        var expressionAttributeNames = new Dictionary<string, string> { ["#s"] = "Status" };
        var expressionAttributeValues = new Dictionary<string, AttributeValue>
        {
            [":status"] = new(status)
        };

        if (processingStartedBefore.HasValue)
            expressionAttributeValues[":leaseExpiredBefore"] = new(processingStartedBefore.Value.ToString("O"));

        var response = await Dynamo.QueryAsync(new QueryRequest
        {
            TableName = TableName,
            IndexName = "GSI-Status-CreatedAt",
            KeyConditionExpression = "#s = :status",
            FilterExpression = processingStartedBefore.HasValue
                ? "attribute_exists(ProcessingStartedAt) AND ProcessingStartedAt <= :leaseExpiredBefore"
                : null,
            ExpressionAttributeNames = expressionAttributeNames,
            ExpressionAttributeValues = expressionAttributeValues,
            Limit = limit
        }, ct);

        return Items(response).Select(FromItem).ToList();
    }

    public Task MarkProcessedAsync(OutboxEvent outboxEvent, CancellationToken ct = default) =>
        MarkProcessedInternalAsync(outboxEvent.AggregateId, outboxEvent.CreatedAt, ct);

    public Task<bool> TryStartProcessingAsync(OutboxEvent outboxEvent, CancellationToken ct = default) =>
        TryStartProcessingInternalAsync(outboxEvent.AggregateId, outboxEvent.CreatedAt, ct);

    public Task MarkPendingAsync(OutboxEvent outboxEvent, CancellationToken ct = default) =>
        MarkPendingInternalAsync(outboxEvent.AggregateId, outboxEvent.CreatedAt, ct);

    internal async Task<bool> TryStartProcessingInternalAsync(Guid id, DateTime createdAt, CancellationToken ct = default)
    {
        try
        {
            await Dynamo.UpdateItemAsync(new UpdateItemRequest
            {
                TableName = TableName,
                Key = Key(DynamoKeys.Outbox(id), DynamoKeys.EventCreatedAt(createdAt)),
                ConditionExpression = "attribute_exists(#s) AND (#s = :pending OR (#s = :processing AND attribute_exists(ProcessingStartedAt) AND ProcessingStartedAt <= :leaseExpiredBefore))",
                UpdateExpression = "SET #s = :processing, ProcessingStartedAt = :now",
                ExpressionAttributeNames = new() { ["#s"] = "Status" },
                ExpressionAttributeValues = new()
                {
                    [":pending"] = new(PendingStatus),
                    [":processing"] = new(ProcessingStatus),
                    [":leaseExpiredBefore"] = new(DateTime.UtcNow.Subtract(ProcessingLease).ToString("O")),
                    [":now"] = new(DateTime.UtcNow.ToString("O"))
                }
            }, ct);

            return true;
        }
        catch (ConditionalCheckFailedException)
        {
            return false;
        }
    }

    internal async Task MarkProcessedInternalAsync(Guid id, DateTime createdAt, CancellationToken ct = default)
    {
        await Dynamo.UpdateItemAsync(new UpdateItemRequest
        {
            TableName = TableName,
            Key = Key(DynamoKeys.Outbox(id), DynamoKeys.EventCreatedAt(createdAt)),
            ConditionExpression = "#s = :processing",
            UpdateExpression = "SET ProcessedAt = :now REMOVE #s, ProcessingStartedAt",
            ExpressionAttributeNames = new() { ["#s"] = "Status" },
            ExpressionAttributeValues = new()
            {
                [":processing"] = new(ProcessingStatus),
                [":now"] = new(DateTime.UtcNow.ToString("O"))
            }
        }, ct);
    }

    internal async Task MarkPendingInternalAsync(Guid id, DateTime createdAt, CancellationToken ct = default)
    {
        await Dynamo.UpdateItemAsync(new UpdateItemRequest
        {
            TableName = TableName,
            Key = Key(DynamoKeys.Outbox(id), DynamoKeys.EventCreatedAt(createdAt)),
            ConditionExpression = "#s = :processing",
            UpdateExpression = "SET #s = :pending REMOVE ProcessingStartedAt",
            ExpressionAttributeNames = new() { ["#s"] = "Status" },
            ExpressionAttributeValues = new()
            {
                [":processing"] = new(ProcessingStatus),
                [":pending"] = new(PendingStatus)
            }
        }, ct);
    }

    private static Dictionary<string, AttributeValue> ToItem(OutboxEvent e)
    {
        var item = new Dictionary<string, AttributeValue>
        {
            ["PK"] = new(DynamoKeys.Outbox(e.AggregateId)),
            ["SK"] = new(DynamoKeys.EventCreatedAt(e.CreatedAt)),
            ["Id"] = new(e.Id.ToString()),
            ["AggregateId"] = new(e.AggregateId.ToString()),
            ["EventType"] = new(e.EventType.ToString()),
            ["Payload"] = new(e.Payload),
            ["CreatedAt"] = new(e.CreatedAt.ToString("O")),
            ["TTL"] = new() { N = new DateTimeOffset(e.CreatedAt.AddDays(7)).ToUnixTimeSeconds().ToString() }
        };

        if (e.ProcessedAt.HasValue)
            item["ProcessedAt"] = new(e.ProcessedAt.Value.ToString("O"));
        else
            item["Status"] = new(PendingStatus);

        return item;
    }

    private static OutboxEvent FromItem(Dictionary<string, AttributeValue> item) => new()
    {
        Id = Guid.Parse(item["Id"].S),
        AggregateId = Guid.Parse(item["AggregateId"].S),
        EventType = Enum.Parse<OutboxEventType>(item["EventType"].S),
        Payload = item["Payload"].S,
        CreatedAt = DateTime.Parse(item["CreatedAt"].S),
        ProcessedAt = item.TryGetValue("ProcessedAt", out var pa) ? DateTime.Parse(pa.S) : null
    };
}
