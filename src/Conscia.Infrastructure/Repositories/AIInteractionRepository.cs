using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.Model;
using Conscia.Application.Interfaces;
using Conscia.Domain.Entities;

namespace Conscia.Infrastructure.Repositories;

public class AIInteractionRepository : DynamoRepository, IAIInteractionRepository
{
    private const string TableName = "AIInteractions";

    public AIInteractionRepository(IAmazonDynamoDB dynamo) : base(dynamo)
    {}

    // ---------------- WRITE ----------------
    public async Task<AIInteraction> AddAsync(AIInteraction interaction, CancellationToken ct = default)
    {
        await Dynamo.PutItemAsync(new PutItemRequest
        {
            TableName = TableName,
            Item = ToItem(interaction)
        }, ct);

        return interaction;
    }

    // ---------------- READ ----------------
    // Uses GSI: TransactionId → CreatedAt
    public async Task<AIInteraction?> GetByTransactionIdAsync(Guid transactionId, CancellationToken ct = default)
    {
        var response = await Dynamo.QueryAsync(new QueryRequest
        {
            TableName = TableName,
            IndexName = "GSI-TransactionId-Date",
            KeyConditionExpression = "TransactionId = :tx",
            ExpressionAttributeValues = new Dictionary<string, AttributeValue>
            {
                [":tx"] = new(transactionId.ToString())
            },
            ScanIndexForward = false,
            Limit = 1,
            ConsistentRead = false // explicit: GSI is eventual
        }, ct);

        return FirstItem(response) is { } item ? FromItem(item) : null;
    }

    // Primary access pattern: USER timeline
    public async Task<IReadOnlyList<AIInteraction>> ListByUserAsync(
        Guid userId,
        DateTime? from,
        DateTime? to,
        int limit = 20,
        CancellationToken ct = default)
    {
        var keyCondition = "PK = :pk";
        var attrValues = new Dictionary<string, AttributeValue>
        {
            [":pk"] = new($"USER#{userId}")
        };

        if (from.HasValue && to.HasValue)
        {
            keyCondition += " AND SK BETWEEN :from AND :to";

            attrValues[":from"] = new(DynamoKeys.DateRangeStart(from.Value));
            attrValues[":to"]   = new(DynamoKeys.DateRangeEnd(to.Value));
        }

        var response = await Dynamo.QueryAsync(new QueryRequest
        {
            TableName = TableName,
            KeyConditionExpression = keyCondition,
            ExpressionAttributeValues = attrValues,
            ScanIndexForward = false,
            Limit = limit
        }, ct);

        return Items(response).Select(FromItem).ToList();
    }

    // Efficient count using PK
    public async Task<int> CountByUserAsync(
        Guid userId,
        DateTime since,
        string? interactionType = null,
        CancellationToken ct = default)
    {
        var attrValues = new Dictionary<string, AttributeValue>
        {
            [":pk"] = new(DynamoKeys.User(userId)),
            [":from"] = new(DynamoKeys.DateRangeStart(since))
        };

        var request = new QueryRequest
        {
            TableName = TableName,
            KeyConditionExpression = "PK = :pk AND SK >= :from",
            ExpressionAttributeValues = attrValues,
            Select = Select.COUNT
        };

        if (interactionType is not null)
        {
            request.FilterExpression = "InteractionType = :type";
            attrValues[":type"] = new(interactionType);
        }

        var response = await Dynamo.QueryAsync(request, ct);
        return response?.Count ?? 0;
    }

    // ---------------- MAPPERS ----------------

    private static Dictionary<string, AttributeValue> ToItem(AIInteraction i)
    {
        return new Dictionary<string, AttributeValue>
        {
            // PRIMARY KEY
            ["PK"] = new(DynamoKeys.User(i.UserId)),
            ["SK"] = new(DynamoKeys.AIInteraction(i.CreatedAt, i.Id)),

            // GSI KEYS
            ["TransactionId"] = new(i.TransactionId.ToString()),
            ["CreatedAt"] = new(i.CreatedAt.ToString("O")),

            // DATA
            ["Id"] = new(i.Id.ToString()),
            ["UserId"] = new(i.UserId.ToString()),
            ["InteractionType"] = new(i.InteractionType ?? "Unknown"),

            ["DevilMsg"] = new(i.DevilMsg),
            ["AngelMsg"] = new(i.AngelMsg),
            ["NeutralMsg"] = new(i.NeutralMsg),

            ["TTL"] = new()
            {
                N = new DateTimeOffset(i.CreatedAt.AddDays(90))
                    .ToUnixTimeSeconds()
                    .ToString()
            }
        };
    }

    private static AIInteraction FromItem(Dictionary<string, AttributeValue> item) => new()
    {
        Id = Guid.Parse(item["Id"].S),
        TransactionId = Guid.Parse(item["TransactionId"].S),
        UserId = Guid.Parse(item["UserId"].S),
        DevilMsg = item["DevilMsg"].S,
        AngelMsg = item["AngelMsg"].S,
        NeutralMsg = item["NeutralMsg"].S,
        InteractionType = item["InteractionType"].S,
        CreatedAt = DateTime.Parse(item["CreatedAt"].S)
    };
}
