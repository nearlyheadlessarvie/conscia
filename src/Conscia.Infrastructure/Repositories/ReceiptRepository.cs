using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.Model;
using Conscia.Application.Interfaces;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using System.Globalization;

namespace Conscia.Infrastructure.Repositories;

public class ReceiptRepository : DynamoRepository, IReceiptRepository
{
    private const string TableName = "ControlPlane";

    public ReceiptRepository(IAmazonDynamoDB dynamo) : base(dynamo)
    {
    }

    public async Task<Receipt?> GetByIdAsync(Guid id, CancellationToken ct = default)
    {
        var response = await Dynamo.GetItemAsync(new GetItemRequest
        {
            TableName = TableName,
            Key = Key(ReceiptPk(id), "PROFILE")
        }, ct);

        return response.Item.Count == 0 ? null : FromItem(response.Item);
    }

    public async Task<Receipt?> GetByTransactionIdAsync(Guid transactionId, CancellationToken ct = default)
    {
        var response = await Dynamo.QueryAsync(new QueryRequest
        {
            TableName = TableName,
            IndexName = "GSI1",
            KeyConditionExpression = "GSI1PK = :pk",
            ExpressionAttributeValues = new Dictionary<string, AttributeValue>
            {
                [":pk"] = new($"TRANSACTION#{transactionId}")
            },
            Limit = 1
        }, ct);

        return response.Items.Count == 0 ? null : FromItem(response.Items[0]);
    }

    public async Task<Receipt> AddAsync(Receipt receipt, CancellationToken ct = default)
    {
        await Dynamo.PutItemAsync(new PutItemRequest
        {
            TableName = TableName,
            Item = ToItem(receipt),
            ConditionExpression = "attribute_not_exists(PK)"
        }, ct);

        return receipt;
    }

    public async Task<Receipt> UpdateAsync(Receipt receipt, CancellationToken ct = default)
    {
        await Dynamo.PutItemAsync(new PutItemRequest
        {
            TableName = TableName,
            Item = ToItem(receipt)
        }, ct);

        return receipt;
    }

    public async Task UpdateStatusAsync(Guid id, ReceiptStatus status, CancellationToken ct = default)
    {
        await Dynamo.UpdateItemAsync(new UpdateItemRequest
        {
            TableName = TableName,
            Key = Key(ReceiptPk(id), "PROFILE"),
            UpdateExpression = "SET #status = :status",
            ExpressionAttributeNames = new Dictionary<string, string>
            {
                ["#status"] = "Status"
            },
            ExpressionAttributeValues = new Dictionary<string, AttributeValue>
            {
                [":status"] = new(status.ToString())
            }
        }, ct);
    }

    internal static string ReceiptPk(Guid id) => $"RECEIPT#{id}";

    internal static Dictionary<string, AttributeValue> ToItem(Receipt receipt)
    {
        var item = new Dictionary<string, AttributeValue>
        {
            ["PK"] = new(ReceiptPk(receipt.Id)),
            ["SK"] = new("PROFILE"),
            ["EntityType"] = new("Receipt"),
            ["Id"] = new(receipt.Id.ToString()),
            ["TransactionId"] = new(receipt.TransactionId.ToString()),
            ["S3Key"] = new(receipt.S3Key),
            ["OcrConfidence"] = NumberValue(receipt.OcrConfidence),
            ["NeedsReview"] = BoolValue(receipt.NeedsReview),
            ["Status"] = new(receipt.Status.ToString()),
            ["CreatedAt"] = new(receipt.CreatedAt.ToString("O", CultureInfo.InvariantCulture)),
            ["GSI1PK"] = new($"TRANSACTION#{receipt.TransactionId}"),
            ["GSI1SK"] = new($"RECEIPT#{receipt.CreatedAt:O}#{receipt.Id}")
        };

        AddIfNotNull(item, "ExtractedData", receipt.ExtractedData);
        return item;
    }

    internal static Receipt FromItem(Dictionary<string, AttributeValue> item) => new()
    {
        Id = Guid.Parse(item["Id"].S),
        TransactionId = Guid.Parse(item["TransactionId"].S),
        S3Key = item["S3Key"].S,
        ExtractedData = GetOptionalString(item, "ExtractedData"),
        OcrConfidence = item.TryGetValue("OcrConfidence", out var confidence) ? GetDouble(item, "OcrConfidence") : 0,
        NeedsReview = GetBool(item, "NeedsReview"),
        Status = item.TryGetValue("Status", out var status) ? Enum.Parse<ReceiptStatus>(status.S) : ReceiptStatus.Pending,
        CreatedAt = item.TryGetValue("CreatedAt", out var created)
            ? DateTime.Parse(created.S, CultureInfo.InvariantCulture, DateTimeStyles.RoundtripKind)
            : DateTime.UtcNow
    };
}
