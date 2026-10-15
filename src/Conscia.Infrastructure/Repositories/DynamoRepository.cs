using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.Model;
using System.Globalization;

namespace Conscia.Infrastructure.Repositories;

public abstract class DynamoRepository
{
    private const int MaxBatchWriteAttempts = 8;

    protected readonly IAmazonDynamoDB Dynamo;

    protected DynamoRepository(IAmazonDynamoDB dynamo)
    {
        Dynamo = dynamo;
    }

    protected static Dictionary<string, AttributeValue> Key(string pk, string? sk = null)
    {
        var key = new Dictionary<string, AttributeValue>
        {
            ["PK"] = new(pk)
        };

        if (sk != null)
            key["SK"] = new(sk);

        return key;
    }

    protected static bool IsMissingItem(Dictionary<string, AttributeValue>? item) =>
        item is null || item.Count == 0;

    protected static IReadOnlyList<Dictionary<string, AttributeValue>> Items(QueryResponse? response) =>
        response?.Items ?? [];

    protected static IReadOnlyList<Dictionary<string, AttributeValue>> Items(ScanResponse? response) =>
        response?.Items ?? [];

    protected static Dictionary<string, AttributeValue>? FirstItem(QueryResponse? response) =>
        Items(response).FirstOrDefault();

    protected static Dictionary<string, AttributeValue>? FirstItem(ScanResponse? response) =>
        Items(response).FirstOrDefault();

    protected static AttributeValue StringValue(string value) => new(value);

    protected static AttributeValue NumberValue(decimal value) =>
        new() { N = value.ToString("G", CultureInfo.InvariantCulture) };

    protected static AttributeValue NumberValue(double value) =>
        new() { N = value.ToString("G", CultureInfo.InvariantCulture) };

    protected static AttributeValue BoolValue(bool value) =>
        new() { BOOL = value };

    protected static void AddIfNotNull(Dictionary<string, AttributeValue> item, string name, string? value)
    {
        if (!string.IsNullOrWhiteSpace(value))
            item[name] = new(value);
    }

    protected static void AddIfNotNull(Dictionary<string, AttributeValue> item, string name, Guid? value)
    {
        if (value.HasValue)
            item[name] = new(value.Value.ToString());
    }

    protected static void AddIfNotNull(Dictionary<string, AttributeValue> item, string name, DateTime? value)
    {
        if (value.HasValue)
            item[name] = new(value.Value.ToString("O", CultureInfo.InvariantCulture));
    }

    protected static string? GetOptionalString(Dictionary<string, AttributeValue> item, string name) =>
        item.TryGetValue(name, out var value) ? value.S : null;

    protected static Guid? GetOptionalGuid(Dictionary<string, AttributeValue> item, string name) =>
        item.TryGetValue(name, out var value) && Guid.TryParse(value.S, out var parsed)
            ? parsed
            : null;

    protected static DateTime? GetOptionalDateTime(Dictionary<string, AttributeValue> item, string name) =>
        item.TryGetValue(name, out var value)
            && DateTime.TryParse(value.S, CultureInfo.InvariantCulture, DateTimeStyles.RoundtripKind, out var parsed)
                ? parsed
                : null;

    protected static bool GetBool(Dictionary<string, AttributeValue> item, string name, bool defaultValue = false) =>
        item.TryGetValue(name, out var value) ? value.BOOL ?? defaultValue : defaultValue;

    protected static decimal GetDecimal(Dictionary<string, AttributeValue> item, string name) =>
        decimal.Parse(item[name].N, CultureInfo.InvariantCulture);

    protected static double GetDouble(Dictionary<string, AttributeValue> item, string name) =>
        double.Parse(item[name].N, CultureInfo.InvariantCulture);

    protected static string NormalizeKeyPart(string value) =>
        value.Trim().ToLowerInvariant();

    protected async Task BatchWriteAllAsync(
        Dictionary<string, List<WriteRequest>> requestItems,
        CancellationToken ct)
    {
        foreach (var (tableName, requests) in requestItems)
        {
            foreach (var batch in requests.Chunk(25))
            {
                var pending = new Dictionary<string, List<WriteRequest>>
                {
                    [tableName] = batch.ToList()
                };

                for (var attempt = 1; pending.Count > 0; attempt++)
                {
                    var response = await Dynamo.BatchWriteItemAsync(new BatchWriteItemRequest
                    {
                        RequestItems = pending
                    }, ct);

                    pending = response.UnprocessedItems?
                        .Where(entry => entry.Value.Count > 0)
                        .ToDictionary(entry => entry.Key, entry => entry.Value)
                        ?? [];

                    if (pending.Count == 0)
                        break;

                    if (attempt >= MaxBatchWriteAttempts)
                        throw new InvalidOperationException("DynamoDB batch write left unprocessed items after retries.");

                    await Task.Delay(BatchWriteRetryDelay(attempt), ct);
                }
            }
        }
    }

    private static TimeSpan BatchWriteRetryDelay(int attempt) =>
        TimeSpan.FromMilliseconds(Math.Min(1000, 25 * Math.Pow(2, attempt - 1)));
}
