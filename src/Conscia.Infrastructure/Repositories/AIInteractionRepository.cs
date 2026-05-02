using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.Model;
using Conscia.Application.Interfaces;
using Conscia.Domain.Entities;

namespace Conscia.Infrastructure.Repositories;

public class AIInteractionRepository : IAIInteractionRepository
{
    private const string TableName = "AIInteractions";
    private readonly IAmazonDynamoDB _dynamo;

    public AIInteractionRepository(IAmazonDynamoDB dynamo) => _dynamo = dynamo;

    public async Task<AIInteraction> AddAsync(AIInteraction interaction, CancellationToken ct = default)
    {
        await _dynamo.PutItemAsync(new PutItemRequest
        {
            TableName = TableName,
            Item = ToItem(interaction)
        }, ct);

        return interaction;
    }

    public async Task<AIInteraction?> GetByTransactionIdAsync(Guid transactionId, CancellationToken ct = default)
    {
        var response = await _dynamo.QueryAsync(new QueryRequest
        {
            TableName = TableName,
            KeyConditionExpression = "PK = :pk",
            ExpressionAttributeValues = new Dictionary<string, AttributeValue>
            {
                [":pk"] = new($"TXN#{transactionId}")
            },
            ScanIndexForward = false,
            Limit = 1
        }, ct);

        return response.Items.Count > 0 ? FromItem(response.Items[0]) : null;
    }

    public async Task<IReadOnlyList<AIInteraction>> ListByUserAsync(
        Guid userId, DateTime? from, DateTime? to, int limit = 20, CancellationToken ct = default)
    {
        var keyCondition = "UserId = :uid";
        var attrValues = new Dictionary<string, AttributeValue>
        {
            [":uid"] = new(userId.ToString())
        };

        if (from.HasValue && to.HasValue)
        {
            keyCondition += " AND #date BETWEEN :from AND :to";
            attrValues[":from"] = new(from.Value.ToString("yyyy-MM-dd"));
            attrValues[":to"] = new(to.Value.ToString("yyyy-MM-dd"));
        }

        var request = new QueryRequest
        {
            TableName = TableName,
            IndexName = "GSI1-UserId-Date",
            KeyConditionExpression = keyCondition,
            ExpressionAttributeValues = attrValues,
            ScanIndexForward = false,
            Limit = limit
        };

        if (from.HasValue && to.HasValue)
        {
            request.ExpressionAttributeNames = new Dictionary<string, string>
            {
                ["#date"] = "Date"
            };
        }

        var response = await _dynamo.QueryAsync(request, ct);
        return response.Items.Select(FromItem).ToList();
    }

    public async Task<int> CountByUserAsync(Guid userId, DateTime since, string? interactionType = null, CancellationToken ct = default)
    {
        var attrValues = new Dictionary<string, AttributeValue>
        {
            [":uid"] = new(userId.ToString()),
            [":since"] = new(since.ToString("yyyy-MM-dd"))
        };

        var request = new QueryRequest
        {
            TableName = TableName,
            IndexName = "GSI1-UserId-Date",
            KeyConditionExpression = "UserId = :uid AND #date >= :since",
            ExpressionAttributeValues = attrValues,
            ExpressionAttributeNames = new Dictionary<string, string>
            {
                ["#date"] = "Date"
            },
            Select = Select.COUNT
        };

        if (interactionType is not null)
        {
            request.FilterExpression = "InteractionType = :itype";
            attrValues[":itype"] = new(interactionType);
        }

        var response = await _dynamo.QueryAsync(request, ct);
        return response.Count ?? 0;
    }

    private static Dictionary<string, AttributeValue> ToItem(AIInteraction i)
    {
        return new Dictionary<string, AttributeValue>
        {
            ["PK"] = new($"TXN#{i.TransactionId}"),
            ["SK"] = new($"AI#{i.CreatedAt:O}"),
            ["Id"] = new(i.Id.ToString()),
            ["TransactionId"] = new(i.TransactionId.ToString()),
            ["UserId"] = new(i.UserId.ToString()),
            ["Date"] = new(i.CreatedAt.ToString("yyyy-MM-dd")),
            ["DevilMsg"] = new(i.DevilMsg),
            ["AngelMsg"] = new(i.AngelMsg),
            ["NeutralMsg"] = new(i.NeutralMsg),
            ["CreatedAt"] = new(i.CreatedAt.ToString("O")),
            ["TTL"] = new() { N = new DateTimeOffset(i.CreatedAt.AddDays(90)).ToUnixTimeSeconds().ToString() },
            ["InteractionType"] = new(i.InteractionType ?? "Unknown")
        };
    }

    private static AIInteraction FromItem(Dictionary<string, AttributeValue> item) => new()
    {
        Id = Guid.Parse(item["Id"].S),
        TransactionId = Guid.Parse(item["TransactionId"].S),
        UserId = item.TryGetValue("UserId", out var uid) ? Guid.Parse(uid.S) : Guid.Empty,
        DevilMsg = item["DevilMsg"].S,
        AngelMsg = item["AngelMsg"].S,
        NeutralMsg = item["NeutralMsg"].S,
        InteractionType = item.TryGetValue("InteractionType", out var itype) ? itype.S : null,
        CreatedAt = DateTime.Parse(item["CreatedAt"].S)
    };
}
