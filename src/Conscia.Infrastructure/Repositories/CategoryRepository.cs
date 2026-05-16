using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.Model;
using Conscia.Application.Interfaces;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using System.Globalization;

namespace Conscia.Infrastructure.Repositories;

public class CategoryRepository : DynamoRepository, ICategoryRepository
{
    private const string TableName = "ControlPlane";

    public CategoryRepository(IAmazonDynamoDB dynamo) : base(dynamo)
    {
    }

    public async Task<ManagedCategory?> GetByIdAsync(Guid id, CancellationToken ct = default)
    {
        var response = await Dynamo.GetItemAsync(new GetItemRequest
        {
            TableName = TableName,
            Key = Key(CategoryPk(id), "PROFILE")
        }, ct);

        return response.Item.Count == 0 ? null : FromItem(response.Item);
    }

    public async Task<ManagedCategory?> GetByNormalizedNameAsync(
        Guid userId,
        Guid? familySpaceId,
        RecordScope scope,
        TransactionType type,
        string normalizedName,
        CancellationToken ct = default)
    {
        var response = await Dynamo.GetItemAsync(new GetItemRequest
        {
            TableName = TableName,
            Key = Key(UniquePk(userId, familySpaceId, scope, type, normalizedName), "CATEGORY")
        }, ct);

        if (response.Item.Count == 0 || !response.Item.TryGetValue("CategoryId", out var categoryId))
            return null;

        return Guid.TryParse(categoryId.S, out var parsed)
            ? await GetByIdAsync(parsed, ct)
            : null;
    }

    public async Task<IReadOnlyList<ManagedCategory>> ListPersonalAsync(Guid userId, CancellationToken ct = default)
    {
        var response = await Dynamo.QueryAsync(new QueryRequest
        {
            TableName = TableName,
            IndexName = "GSI1",
            KeyConditionExpression = "GSI1PK = :pk",
            ExpressionAttributeValues = new Dictionary<string, AttributeValue>
            {
                [":pk"] = new(UserRepository.UserPk(userId))
            }
        }, ct);

        return response.Items
            .Where(item => item.TryGetValue("EntityType", out var type) && type.S == "ManagedCategory")
            .Select(FromItem)
            .ToList();
    }

    public async Task<IReadOnlyList<ManagedCategory>> ListByFamilySpaceAsync(Guid familySpaceId, CancellationToken ct = default)
    {
        var response = await Dynamo.QueryAsync(new QueryRequest
        {
            TableName = TableName,
            IndexName = "GSI2",
            KeyConditionExpression = "GSI2PK = :pk",
            ExpressionAttributeValues = new Dictionary<string, AttributeValue>
            {
                [":pk"] = new(FamilySpaceRepository.FamilyPk(familySpaceId))
            }
        }, ct);

        return response.Items
            .Where(item => item.TryGetValue("EntityType", out var type) && type.S == "ManagedCategory")
            .Select(FromItem)
            .ToList();
    }

    public async Task<ManagedCategory> AddAsync(ManagedCategory category, CancellationToken ct = default)
    {
        category.NormalizedName = NormalizeKeyPart(category.NormalizedName);

        await Dynamo.TransactWriteItemsAsync(new TransactWriteItemsRequest
        {
            TransactItems =
            [
                new()
                {
                    Put = new Put
                    {
                        TableName = TableName,
                        Item = ToItem(category),
                        ConditionExpression = "attribute_not_exists(PK)"
                    }
                },
                new()
                {
                    Put = new Put
                    {
                        TableName = TableName,
                        Item = UniqueSentinel(category),
                        ConditionExpression = "attribute_not_exists(PK)"
                    }
                }
            ]
        }, ct);

        return category;
    }

    public async Task<ManagedCategory> UpdateAsync(ManagedCategory category, CancellationToken ct = default)
    {
        category.NormalizedName = NormalizeKeyPart(category.NormalizedName);
        var existing = await GetByIdAsync(category.Id, ct);
        var writes = new List<TransactWriteItem>();

        if (existing is not null && UniquePk(existing) != UniquePk(category))
        {
            writes.Add(new TransactWriteItem
            {
                Delete = new Delete
                {
                    TableName = TableName,
                    Key = Key(UniquePk(existing), "CATEGORY")
                }
            });
            writes.Add(new TransactWriteItem
            {
                Put = new Put
                {
                    TableName = TableName,
                    Item = UniqueSentinel(category),
                    ConditionExpression = "attribute_not_exists(PK)"
                }
            });
        }

        writes.Add(new TransactWriteItem
        {
            Put = new Put
            {
                TableName = TableName,
                Item = ToItem(category)
            }
        });

        await Dynamo.TransactWriteItemsAsync(new TransactWriteItemsRequest { TransactItems = writes }, ct);
        return category;
    }

    internal static string CategoryPk(Guid id) => $"CATEGORY#{id}";

    internal static Dictionary<string, AttributeValue> ToItem(ManagedCategory category)
    {
        var item = new Dictionary<string, AttributeValue>
        {
            ["PK"] = new(CategoryPk(category.Id)),
            ["SK"] = new("PROFILE"),
            ["EntityType"] = new("ManagedCategory"),
            ["Id"] = new(category.Id.ToString()),
            ["UserId"] = new(category.UserId.ToString()),
            ["Name"] = new(category.Name),
            ["NormalizedName"] = new(NormalizeKeyPart(category.NormalizedName)),
            ["Type"] = new(category.Type.ToString()),
            ["Scope"] = new(category.Scope.ToString()),
            ["IconKey"] = new(category.IconKey),
            ["ColorKey"] = new(category.ColorKey),
            ["IsArchived"] = BoolValue(category.IsArchived),
            ["IsDefault"] = BoolValue(category.IsDefault),
            ["CreatedAt"] = new(category.CreatedAt.ToString("O", CultureInfo.InvariantCulture)),
            ["UpdatedAt"] = new(category.UpdatedAt.ToString("O", CultureInfo.InvariantCulture)),
            ["GSI1PK"] = new(UserRepository.UserPk(category.UserId)),
            ["GSI1SK"] = new($"CATEGORY#{category.Type}#{NormalizeKeyPart(category.NormalizedName)}")
        };

        AddIfNotNull(item, "FamilySpaceId", category.FamilySpaceId);

        if (category.Scope == RecordScope.Family && category.FamilySpaceId.HasValue)
        {
            item["GSI2PK"] = new(FamilySpaceRepository.FamilyPk(category.FamilySpaceId.Value));
            item["GSI2SK"] = new($"CATEGORY#{category.Type}#{NormalizeKeyPart(category.NormalizedName)}");
        }

        return item;
    }

    internal static ManagedCategory FromItem(Dictionary<string, AttributeValue> item) => new()
    {
        Id = Guid.Parse(item["Id"].S),
        UserId = Guid.Parse(item["UserId"].S),
        Name = item["Name"].S,
        NormalizedName = item["NormalizedName"].S,
        Type = Enum.Parse<TransactionType>(item["Type"].S),
        Scope = Enum.Parse<RecordScope>(item["Scope"].S),
        FamilySpaceId = GetOptionalGuid(item, "FamilySpaceId"),
        IconKey = item.TryGetValue("IconKey", out var icon) ? icon.S : "other",
        ColorKey = item.TryGetValue("ColorKey", out var color) ? color.S : "blue",
        IsArchived = GetBool(item, "IsArchived"),
        IsDefault = GetBool(item, "IsDefault"),
        CreatedAt = item.TryGetValue("CreatedAt", out var created)
            ? DateTime.Parse(created.S, CultureInfo.InvariantCulture, DateTimeStyles.RoundtripKind)
            : DateTime.UtcNow,
        UpdatedAt = item.TryGetValue("UpdatedAt", out var updated)
            ? DateTime.Parse(updated.S, CultureInfo.InvariantCulture, DateTimeStyles.RoundtripKind)
            : DateTime.UtcNow
    };

    private static Dictionary<string, AttributeValue> UniqueSentinel(ManagedCategory category) => new()
    {
        ["PK"] = new(UniquePk(category)),
        ["SK"] = new("CATEGORY"),
        ["EntityType"] = new("ManagedCategoryUnique"),
        ["CategoryId"] = new(category.Id.ToString())
    };

    private static string UniquePk(ManagedCategory category) =>
        UniquePk(category.UserId, category.FamilySpaceId, category.Scope, category.Type, category.NormalizedName);

    private static string UniquePk(
        Guid userId,
        Guid? familySpaceId,
        RecordScope scope,
        TransactionType type,
        string normalizedName)
    {
        var owner = scope == RecordScope.Family
            ? familySpaceId?.ToString() ?? "missing-family"
            : userId.ToString();
        return $"CATEGORY_UNIQUE#{scope}#{owner}#{type}#{NormalizeKeyPart(normalizedName)}";
    }
}
