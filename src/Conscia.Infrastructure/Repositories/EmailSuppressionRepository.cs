using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.Model;
using Conscia.Application.Interfaces;
using Conscia.Domain.Entities;

namespace Conscia.Infrastructure.Repositories;

public class EmailSuppressionRepository : DynamoRepository, IEmailSuppressionRepository
{
    private const string TableName = "EmailSuppressions";

    public EmailSuppressionRepository(IAmazonDynamoDB dynamo) : base(dynamo)
    {}

    public async Task<bool> IsSuppressedAsync(string email, CancellationToken ct = default)
    {
        var normalized = NormalizeEmail(email);
        var response = await Dynamo.GetItemAsync(new GetItemRequest
        {
            TableName = TableName,
            Key = Key(DynamoKeys.EmailSuppression(normalized))
        }, ct);

        return !IsMissingItem(response.Item);
    }

    public async Task UpsertAsync(EmailSuppression suppression, CancellationToken ct = default)
    {
        var normalized = NormalizeEmail(suppression.Email);
        suppression.Email = normalized;

        await Dynamo.PutItemAsync(new PutItemRequest
        {
            TableName = TableName,
            Item = ToItem(suppression)
        }, ct);
    }

    private static Dictionary<string, AttributeValue> ToItem(EmailSuppression suppression)
    {
        var item = new Dictionary<string, AttributeValue>
        {
            ["PK"] = new(DynamoKeys.EmailSuppression(suppression.Email)),
            ["Email"] = new(suppression.Email),
            ["Reason"] = new(suppression.Reason.ToString()),
            ["Source"] = new(suppression.Source),
            ["SuppressedAt"] = new(suppression.SuppressedAt.ToString("O"))
        };

        AddIfNotNull(item, "SourceEventId", suppression.SourceEventId);
        AddIfNotNull(item, "ProviderMessageId", suppression.ProviderMessageId);

        return item;
    }

    private static string NormalizeEmail(string email)
    {
        if (string.IsNullOrWhiteSpace(email))
            throw new InvalidOperationException("Email suppression address is required.");

        return email.Trim().ToLowerInvariant();
    }
}
