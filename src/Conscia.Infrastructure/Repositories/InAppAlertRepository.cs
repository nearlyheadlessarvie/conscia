using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.Model;
using Conscia.Application.Interfaces;
using Conscia.Application.Models;

namespace Conscia.Infrastructure.Repositories;

public class InAppAlertRepository : DynamoRepository, IInAppAlertRepository
{
    private const string TableName = "InAppAlerts";

    public InAppAlertRepository(IAmazonDynamoDB dynamo) : base(dynamo)
    {}

    public async Task AddAsync(InAppAlert alert, CancellationToken ct = default)
    {
        await Dynamo.PutItemAsync(new PutItemRequest
        {
            TableName = TableName,
            Item = ToItem(alert)
        }, ct);
    }

    public async Task<IReadOnlyList<InAppAlert>> GetByUserAsync(Guid userId, CancellationToken ct = default)
    {
        var response = await Dynamo.QueryAsync(new QueryRequest
        {
            TableName = TableName,
            KeyConditionExpression = "PK = :pk",
            ExpressionAttributeValues = new Dictionary<string, AttributeValue>
            {
                [":pk"] = new(DynamoKeys.User(userId))
            },
            ScanIndexForward = false
        }, ct);

        return response.Items.Select(FromItem).ToList();
    }

    private static Dictionary<string, AttributeValue> ToItem(InAppAlert a)
    {
        var item = new Dictionary<string, AttributeValue>
        {
            ["PK"] = new(DynamoKeys.User(a.UserId)),
            ["SK"] = new(DynamoKeys.Alert(a.CreatedAt)),
            ["Id"] = new(a.Id.ToString()),
            ["AlertKey"] = new(a.AlertKey),
            ["UserId"] = new(a.UserId.ToString()),
            ["TriggerName"] = new(a.TriggerName),
            ["Title"] = new(a.Title),
            ["Message"] = new(a.Message),
            ["Priority"] = new() { N = a.Priority.ToString() },
            ["CreatedAt"] = new(a.CreatedAt.ToString("O")),
            ["TTL"] = new() { N = a.TTL.ToString() }
        };

        if (!string.IsNullOrWhiteSpace(a.ActionLabel))
            item["ActionLabel"] = new(a.ActionLabel);

        if (!string.IsNullOrWhiteSpace(a.ActionRoute))
            item["ActionRoute"] = new(a.ActionRoute);

        if (!string.IsNullOrWhiteSpace(a.Category))
            item["Category"] = new(a.Category);

        if (!string.IsNullOrWhiteSpace(a.Counterparty))
            item["Counterparty"] = new(a.Counterparty);

        if (a.TransactionId.HasValue)
            item["TransactionId"] = new(a.TransactionId.Value.ToString());

        return item;
    }

    private static InAppAlert FromItem(Dictionary<string, AttributeValue> item)
    {
        var alert = new InAppAlert
        {
            Id = Guid.Parse(item["Id"].S),
            AlertKey = item.TryGetValue("AlertKey", out var alertKey) ? alertKey.S : string.Empty,
            UserId = Guid.Parse(item["UserId"].S),
            TriggerName = item["TriggerName"].S,
            Title = item["Title"].S,
            Message = item["Message"].S,
            Priority = item.TryGetValue("Priority", out var priority) && int.TryParse(priority.N, out var parsedPriority)
                ? parsedPriority
                : 0,
            CreatedAt = DateTime.Parse(item["CreatedAt"].S),
            TTL = long.Parse(item["TTL"].N)
        };

        if (item.TryGetValue("ActionLabel", out var actionLabel))
            alert.ActionLabel = actionLabel.S;

        if (item.TryGetValue("ActionRoute", out var actionRoute))
            alert.ActionRoute = actionRoute.S;

        if (item.TryGetValue("Category", out var category))
            alert.Category = category.S;

        if (item.TryGetValue("Counterparty", out var counterparty))
            alert.Counterparty = counterparty.S;

        if (item.TryGetValue("TransactionId", out var transactionId)
            && Guid.TryParse(transactionId.S, out var parsedTransactionId))
        {
            alert.TransactionId = parsedTransactionId;
        }

        return alert;
    }
}
