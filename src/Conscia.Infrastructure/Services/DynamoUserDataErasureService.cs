using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.Model;
using Amazon.S3;
using Amazon.S3.Model;
using Conscia.Application.Interfaces;
using Conscia.Domain.Enums;
using Conscia.Infrastructure.Repositories;
using Microsoft.Extensions.Configuration;

namespace Conscia.Infrastructure.Services;

public sealed class DynamoUserDataErasureService : DynamoRepository, IUserDataErasureService
{
    private const string ControlPlaneTable = "ControlPlane";

    private static readonly string[] UserPartitionTables =
    [
        "Transactions",
        "RecurringSchedules",
        "AIInteractions",
        "InAppAlerts",
        "WeeklyInsights",
        "PurchasePatterns",
        "MonthlyCategorySpends",
        "PushDeviceTokens",
        "ConscienceJourney"
    ];

    private readonly IAmazonS3 _s3;
    private readonly string _bucketName;

    public DynamoUserDataErasureService(
        IAmazonDynamoDB dynamo,
        IAmazonS3 s3,
        IConfiguration config) : base(dynamo)
    {
        _s3 = s3;
        _bucketName = config["AWS:S3:BucketName"] ?? "conscia-receipts";
    }

    public async Task EraseUserDataAsync(Guid userId, CancellationToken ct = default)
    {
        var deletes = new Dictionary<string, List<WriteRequest>>();
        var queuedKeys = new HashSet<string>(StringComparer.Ordinal);
        var s3Keys = new HashSet<string>(StringComparer.Ordinal);
        var userPk = DynamoKeys.User(userId);

        foreach (var tableName in UserPartitionTables)
        {
            var items = await QueryAllByPartitionAsync(tableName, userPk, ct);
            foreach (var item in items)
            {
                QueueDelete(deletes, queuedKeys, tableName, item);

                if (tableName == "Transactions")
                    QueueRecurringOccurrenceSentinelDelete(deletes, queuedKeys, item);
            }
        }

        var ownedFamilySpaceIds = await QueueControlPlaneUserOwnedDeletesAsync(userId, deletes, queuedKeys, s3Keys, ct);
        foreach (var familySpaceId in ownedFamilySpaceIds)
            await QueueOwnedFamilySpaceDeletesAsync(familySpaceId, deletes, queuedKeys, s3Keys, ct);

        await FlushDeletesAsync(deletes, ct);

        await DeleteS3PrefixAsync($"profile-pictures/{userId}/", ct);
        await DeleteS3PrefixAsync($"receipts/{userId}/", ct);
        await DeleteS3ObjectsAsync(s3Keys, ct);
    }

    private async Task<IReadOnlyList<Dictionary<string, AttributeValue>>> QueryAllByPartitionAsync(
        string tableName,
        string pk,
        CancellationToken ct)
    {
        var items = new List<Dictionary<string, AttributeValue>>();
        Dictionary<string, AttributeValue>? lastEvaluatedKey = null;

        do
        {
            var response = await Dynamo.QueryAsync(new QueryRequest
            {
                TableName = tableName,
                KeyConditionExpression = "PK = :pk",
                ExpressionAttributeValues = new Dictionary<string, AttributeValue>
                {
                    [":pk"] = new(pk)
                },
                ExclusiveStartKey = lastEvaluatedKey
            }, ct);

            items.AddRange(Items(response));
            lastEvaluatedKey = response.LastEvaluatedKey;
        }
        while (lastEvaluatedKey is { Count: > 0 });

        return items;
    }

    private async Task<IReadOnlyCollection<Guid>> QueueControlPlaneUserOwnedDeletesAsync(
        Guid userId,
        Dictionary<string, List<WriteRequest>> deletes,
        HashSet<string> queuedKeys,
        HashSet<string> s3Keys,
        CancellationToken ct)
    {
        var userIdValue = userId.ToString();
        var ownedFamilySpaceIds = new HashSet<Guid>();
        Dictionary<string, AttributeValue>? lastEvaluatedKey = null;

        do
        {
            var response = await Dynamo.ScanAsync(new ScanRequest
            {
                TableName = ControlPlaneTable,
                FilterExpression = "UserId = :userId OR InvitedByUserId = :userId OR CreatedByUserId = :userId",
                ExpressionAttributeValues = new Dictionary<string, AttributeValue>
                {
                    [":userId"] = new(userIdValue)
                },
                ExclusiveStartKey = lastEvaluatedKey
            }, ct);

            foreach (var item in Items(response))
            {
                QueueControlPlaneDeletes(item, deletes, queuedKeys, s3Keys);

                if (item.TryGetValue("EntityType", out var type)
                    && type.S == "FamilySpace"
                    && item.TryGetValue("Id", out var id)
                    && Guid.TryParse(id.S, out var familySpaceId))
                {
                    ownedFamilySpaceIds.Add(familySpaceId);
                }
            }

            lastEvaluatedKey = response.LastEvaluatedKey;
        }
        while (lastEvaluatedKey is { Count: > 0 });

        QueueDelete(deletes, queuedKeys, ControlPlaneTable, $"MEMBER_USER#{userId}", "MEMBERSHIP");
        return ownedFamilySpaceIds;
    }

    private async Task QueueOwnedFamilySpaceDeletesAsync(
        Guid familySpaceId,
        Dictionary<string, List<WriteRequest>> deletes,
        HashSet<string> queuedKeys,
        HashSet<string> s3Keys,
        CancellationToken ct)
    {
        await QueueFamilySpacePartitionDeletesAsync(familySpaceId, deletes, queuedKeys, s3Keys, ct);
        await QueueFamilySpaceControlPlaneReferenceDeletesAsync(familySpaceId, deletes, queuedKeys, s3Keys, ct);

        foreach (var tableName in UserPartitionTables)
            await QueueFamilySpaceTableDeletesAsync(tableName, familySpaceId, deletes, queuedKeys, ct);
    }

    private async Task QueueFamilySpacePartitionDeletesAsync(
        Guid familySpaceId,
        Dictionary<string, List<WriteRequest>> deletes,
        HashSet<string> queuedKeys,
        HashSet<string> s3Keys,
        CancellationToken ct)
    {
        Dictionary<string, AttributeValue>? lastEvaluatedKey = null;

        do
        {
            var response = await Dynamo.QueryAsync(new QueryRequest
            {
                TableName = ControlPlaneTable,
                KeyConditionExpression = "PK = :pk",
                ExpressionAttributeValues = new Dictionary<string, AttributeValue>
                {
                    [":pk"] = new(FamilySpaceRepository.FamilyPk(familySpaceId))
                },
                ExclusiveStartKey = lastEvaluatedKey
            }, ct);

            foreach (var item in Items(response))
                QueueControlPlaneDeletes(item, deletes, queuedKeys, s3Keys);

            lastEvaluatedKey = response.LastEvaluatedKey;
        }
        while (lastEvaluatedKey is { Count: > 0 });
    }

    private async Task QueueFamilySpaceControlPlaneReferenceDeletesAsync(
        Guid familySpaceId,
        Dictionary<string, List<WriteRequest>> deletes,
        HashSet<string> queuedKeys,
        HashSet<string> s3Keys,
        CancellationToken ct)
    {
        Dictionary<string, AttributeValue>? lastEvaluatedKey = null;

        do
        {
            var response = await Dynamo.ScanAsync(new ScanRequest
            {
                TableName = ControlPlaneTable,
                FilterExpression = "FamilySpaceId = :familySpaceId OR GSI2PK = :familyPk",
                ExpressionAttributeValues = new Dictionary<string, AttributeValue>
                {
                    [":familySpaceId"] = new(familySpaceId.ToString()),
                    [":familyPk"] = new(FamilySpaceRepository.FamilyPk(familySpaceId))
                },
                ExclusiveStartKey = lastEvaluatedKey
            }, ct);

            foreach (var item in Items(response))
                QueueControlPlaneDeletes(item, deletes, queuedKeys, s3Keys);

            lastEvaluatedKey = response.LastEvaluatedKey;
        }
        while (lastEvaluatedKey is { Count: > 0 });
    }

    private async Task QueueFamilySpaceTableDeletesAsync(
        string tableName,
        Guid familySpaceId,
        Dictionary<string, List<WriteRequest>> deletes,
        HashSet<string> queuedKeys,
        CancellationToken ct)
    {
        Dictionary<string, AttributeValue>? lastEvaluatedKey = null;

        do
        {
            var response = await Dynamo.ScanAsync(new ScanRequest
            {
                TableName = tableName,
                FilterExpression = "FamilySpaceId = :familySpaceId",
                ExpressionAttributeValues = new Dictionary<string, AttributeValue>
                {
                    [":familySpaceId"] = new(familySpaceId.ToString())
                },
                ExclusiveStartKey = lastEvaluatedKey
            }, ct);

            foreach (var item in Items(response))
            {
                QueueDelete(deletes, queuedKeys, tableName, item);

                if (tableName == "Transactions")
                    QueueRecurringOccurrenceSentinelDelete(deletes, queuedKeys, item);
            }

            lastEvaluatedKey = response.LastEvaluatedKey;
        }
        while (lastEvaluatedKey is { Count: > 0 });
    }

    private static void QueueControlPlaneDeletes(
        Dictionary<string, AttributeValue> item,
        Dictionary<string, List<WriteRequest>> deletes,
        HashSet<string> queuedKeys,
        HashSet<string> s3Keys)
    {
        QueueDelete(deletes, queuedKeys, ControlPlaneTable, item);

        var entityType = item.TryGetValue("EntityType", out var type) ? type.S : null;
        switch (entityType)
        {
            case "Budget":
                QueueBudgetUniqueDelete(deletes, queuedKeys, item);
                break;
            case "ManagedCategory":
                QueueCategoryUniqueDelete(deletes, queuedKeys, item);
                break;
            case "Receipt":
                if (item.TryGetValue("S3Key", out var s3Key) && !string.IsNullOrWhiteSpace(s3Key.S))
                    s3Keys.Add(s3Key.S);
                break;
            case "FamilyMember":
                if (item.TryGetValue("UserId", out var memberUserId) && Guid.TryParse(memberUserId.S, out var parsedMemberUserId))
                    QueueDelete(deletes, queuedKeys, ControlPlaneTable, $"MEMBER_USER#{parsedMemberUserId}", "MEMBERSHIP");
                break;
            case "UserSubscription":
                if (item.TryGetValue("OriginalTransactionId", out var originalTransactionId))
                {
                    QueueDelete(
                        deletes,
                        queuedKeys,
                        ControlPlaneTable,
                        UserRepository.SubscriptionOriginalPk(originalTransactionId.S),
                        "SUBSCRIPTION");
                }
                break;
        }
    }

    private static void QueueBudgetUniqueDelete(
        Dictionary<string, List<WriteRequest>> deletes,
        HashSet<string> queuedKeys,
        Dictionary<string, AttributeValue> item)
    {
        if (!item.TryGetValue("UserId", out var userId)
            || !item.TryGetValue("Scope", out var scope)
            || !item.TryGetValue("Category", out var category))
        {
            return;
        }

        var owner = scope.S == RecordScope.Family.ToString()
            ? item.TryGetValue("FamilySpaceId", out var familySpaceId) ? familySpaceId.S : "missing-family"
            : userId.S;

        QueueDelete(
            deletes,
            queuedKeys,
            ControlPlaneTable,
            $"BUDGET_UNIQUE#{scope.S}#{owner}#{NormalizeKeyPart(category.S)}",
            "BUDGET");
    }

    private static void QueueCategoryUniqueDelete(
        Dictionary<string, List<WriteRequest>> deletes,
        HashSet<string> queuedKeys,
        Dictionary<string, AttributeValue> item)
    {
        if (!item.TryGetValue("UserId", out var userId)
            || !item.TryGetValue("Scope", out var scope)
            || !item.TryGetValue("Type", out var transactionType)
            || !item.TryGetValue("NormalizedName", out var normalizedName))
        {
            return;
        }

        var owner = scope.S == RecordScope.Family.ToString()
            ? item.TryGetValue("FamilySpaceId", out var familySpaceId) ? familySpaceId.S : "missing-family"
            : userId.S;

        QueueDelete(
            deletes,
            queuedKeys,
            ControlPlaneTable,
            $"CATEGORY_UNIQUE#{scope.S}#{owner}#{transactionType.S}#{NormalizeKeyPart(normalizedName.S)}",
            "CATEGORY");
    }

    private static void QueueRecurringOccurrenceSentinelDelete(
        Dictionary<string, List<WriteRequest>> deletes,
        HashSet<string> queuedKeys,
        Dictionary<string, AttributeValue> item)
    {
        if (!item.TryGetValue("RecurringScheduleId", out var recurringScheduleId)
            || !item.TryGetValue("RecurringOccurrenceDate", out var occurrenceDate))
        {
            return;
        }

        QueueDelete(
            deletes,
            queuedKeys,
            "Transactions",
            $"RECURRING#{recurringScheduleId.S}",
            $"OCCURRENCE#{occurrenceDate.S}");
    }

    private static void QueueDelete(
        Dictionary<string, List<WriteRequest>> deletes,
        HashSet<string> queuedKeys,
        string tableName,
        Dictionary<string, AttributeValue> item)
    {
        if (!item.TryGetValue("PK", out var pk) || !item.TryGetValue("SK", out var sk))
            return;

        QueueDelete(deletes, queuedKeys, tableName, pk.S, sk.S);
    }

    private static void QueueDelete(
        Dictionary<string, List<WriteRequest>> deletes,
        HashSet<string> queuedKeys,
        string tableName,
        string pk,
        string sk)
    {
        var key = $"{tableName}|{pk}|{sk}";
        if (!queuedKeys.Add(key))
            return;

        if (!deletes.TryGetValue(tableName, out var requests))
        {
            requests = [];
            deletes[tableName] = requests;
        }

        requests.Add(new WriteRequest
        {
            DeleteRequest = new DeleteRequest
            {
                Key = Key(pk, sk)
            }
        });
    }

    private async Task FlushDeletesAsync(Dictionary<string, List<WriteRequest>> deletes, CancellationToken ct)
    {
        await BatchWriteAllAsync(deletes, ct);
    }

    private async Task DeleteS3PrefixAsync(string prefix, CancellationToken ct)
    {
        string? continuationToken = null;

        do
        {
            var response = await _s3.ListObjectsV2Async(new ListObjectsV2Request
            {
                BucketName = _bucketName,
                Prefix = prefix,
                ContinuationToken = continuationToken
            }, ct);

            await DeleteS3ObjectsAsync(response.S3Objects?.Select(o => o.Key) ?? [], ct);
            continuationToken = response.IsTruncated == true
                ? response.NextContinuationToken
                : null;
        }
        while (continuationToken is not null);
    }

    private async Task DeleteS3ObjectsAsync(IEnumerable<string> keys, CancellationToken ct)
    {
        var objects = keys
            .Where(key => !string.IsNullOrWhiteSpace(key))
            .Distinct(StringComparer.Ordinal)
            .Select(key => new KeyVersion { Key = key })
            .ToList();

        foreach (var batch in objects.Chunk(1000))
        {
            var batchList = batch.ToList();
            if (batchList.Count == 0)
                continue;

            await _s3.DeleteObjectsAsync(new DeleteObjectsRequest
            {
                BucketName = _bucketName,
                Objects = batchList
            }, ct);
        }
    }
}
