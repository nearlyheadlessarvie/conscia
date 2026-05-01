using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.Model;
using Conscia.Application.Interfaces;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;

namespace Conscia.Infrastructure.Repositories;

public class OutboxEventRepository : IOutboxEventRepository
{
    private const string TableName = "OutboxEvents";
    private readonly IAmazonDynamoDB _dynamo;

    public OutboxEventRepository(IAmazonDynamoDB dynamo) => _dynamo = dynamo;

    public async Task<OutboxEvent> AddAsync(OutboxEvent outboxEvent, CancellationToken ct = default)
    {
        await _dynamo.PutItemAsync(new PutItemRequest
        {
            TableName = TableName,
            Item = ToItem(outboxEvent)
        }, ct);

        return outboxEvent;
    }

    public async Task<IReadOnlyList<OutboxEvent>> GetPendingAsync(int limit = 50, CancellationToken ct = default)
    {
        var response = await _dynamo.QueryAsync(new QueryRequest
        {
            TableName = TableName,
            IndexName = "GSI1-Status",
            KeyConditionExpression = "#s = :pending",
            ExpressionAttributeNames = new Dictionary<string, string> { ["#s"] = "Status" },
            ExpressionAttributeValues = new Dictionary<string, AttributeValue>
            {
                [":pending"] = new("PENDING")
            },
            Limit = limit
        }, ct);

        return response.Items.Select(FromItem).ToList();
    }

    public async Task MarkProcessedAsync(Guid id, CancellationToken ct = default)
    {
        // Interface contract uses Guid id, but we need the full entity
        // to reconstruct the composite DynamoDB key (PK/SK).
        // Callers (OutboxProcessor) always process from GetPendingAsync results,
        // so we use the overload below for efficiency. This method exists
        // for the interface contract and does a targeted GSI lookup.
        var pending = await GetPendingAsync(200, ct);
        var target = pending.FirstOrDefault(e => e.Id == id)
            ?? throw new InvalidOperationException($"OutboxEvent {id} not found or already processed");

        await MarkProcessedInternalAsync(target.AggregateId, target.CreatedAt, ct);
    }

    public Task MarkProcessedAsync(OutboxEvent outboxEvent, CancellationToken ct = default) =>
        MarkProcessedInternalAsync(outboxEvent.AggregateId, outboxEvent.CreatedAt, ct);

    internal async Task MarkProcessedInternalAsync(Guid aggregateId, DateTime createdAt, CancellationToken ct = default)
    {
        await _dynamo.UpdateItemAsync(new UpdateItemRequest
        {
            TableName = TableName,
            Key = new Dictionary<string, AttributeValue>
            {
                ["PK"] = new($"AGG#{aggregateId}"),
                ["SK"] = new($"EVENT#{createdAt:O}")
            },
            UpdateExpression = "SET ProcessedAt = :now REMOVE #s",
            ExpressionAttributeNames = new Dictionary<string, string> { ["#s"] = "Status" },
            ExpressionAttributeValues = new Dictionary<string, AttributeValue>
            {
                [":now"] = new(DateTime.UtcNow.ToString("O"))
            }
        }, ct);
    }

    private static Dictionary<string, AttributeValue> ToItem(OutboxEvent e)
    {
        var item = new Dictionary<string, AttributeValue>
        {
            ["PK"] = new($"AGG#{e.AggregateId}"),
            ["SK"] = new($"EVENT#{e.CreatedAt:O}"),
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
            item["Status"] = new("PENDING");

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
