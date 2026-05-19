using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.Model;
using Conscia.Application.Interfaces;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;

namespace Conscia.Infrastructure.Repositories;

public class BudgetRepository : DynamoRepository, IBudgetRepository
{
    private const string TableName = "ControlPlane";

    public BudgetRepository(IAmazonDynamoDB dynamo) : base(dynamo)
    {
    }

    public async Task<Budget?> GetByIdAsync(Guid id, CancellationToken ct = default)
    {
        var response = await Dynamo.GetItemAsync(new GetItemRequest
        {
            TableName = TableName,
            Key = Key(BudgetPk(id), "PROFILE")
        }, ct);

        return IsMissingItem(response.Item) ? null : FromItem(response.Item);
    }

    public async Task<IReadOnlyList<Budget>> ListByUserAsync(Guid userId, CancellationToken ct = default)
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

        return Items(response)
            .Where(item => item.TryGetValue("EntityType", out var type) && type.S == "Budget")
            .Select(FromItem)
            .ToList();
    }

    public async Task<IReadOnlyList<Budget>> ListByFamilySpaceAsync(Guid familySpaceId, CancellationToken ct = default)
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

        return Items(response)
            .Where(item => item.TryGetValue("EntityType", out var type) && type.S == "Budget")
            .Select(FromItem)
            .ToList();
    }

    public async Task<Budget> AddAsync(Budget budget, CancellationToken ct = default)
    {
        try
        {
            await Dynamo.TransactWriteItemsAsync(new TransactWriteItemsRequest
            {
                TransactItems =
                [
                    new()
                    {
                        Put = new Put
                        {
                            TableName = TableName,
                            Item = ToItem(budget),
                            ConditionExpression = "attribute_not_exists(PK)"
                        }
                    },
                    new()
                    {
                        Put = new Put
                        {
                            TableName = TableName,
                            Item = UniqueSentinel(budget),
                            ConditionExpression = "attribute_not_exists(PK)"
                        }
                    }
                ]
            }, ct);
        }
        catch (TransactionCanceledException ex)
        {
            throw DuplicateBudgetException(ex);
        }

        return budget;
    }

    public async Task<Budget> UpdateAsync(Budget budget, CancellationToken ct = default)
    {
        var existing = await GetByIdAsync(budget.Id, ct);
        var writes = new List<TransactWriteItem>();

        if (existing is not null && UniquePk(existing) != UniquePk(budget))
        {
            writes.Add(new TransactWriteItem
            {
                Delete = new Delete
                {
                    TableName = TableName,
                    Key = Key(UniquePk(existing), "BUDGET")
                }
            });
            writes.Add(new TransactWriteItem
            {
                Put = new Put
                {
                    TableName = TableName,
                    Item = UniqueSentinel(budget),
                    ConditionExpression = "attribute_not_exists(PK)"
                }
            });
        }

        writes.Add(new TransactWriteItem
        {
            Put = new Put
            {
                TableName = TableName,
                Item = ToItem(budget)
            }
        });

        try
        {
            await Dynamo.TransactWriteItemsAsync(new TransactWriteItemsRequest
            {
                TransactItems = writes
            }, ct);
        }
        catch (TransactionCanceledException ex)
        {
            throw DuplicateBudgetException(ex);
        }

        return budget;
    }

    public async Task DeleteAsync(Guid id, CancellationToken ct = default)
    {
        var existing = await GetByIdAsync(id, ct);
        if (existing is null)
            return;

        await Dynamo.TransactWriteItemsAsync(new TransactWriteItemsRequest
        {
            TransactItems =
            [
                new()
                {
                    Delete = new Delete
                    {
                        TableName = TableName,
                        Key = Key(BudgetPk(id), "PROFILE")
                    }
                },
                new()
                {
                    Delete = new Delete
                    {
                        TableName = TableName,
                        Key = Key(UniquePk(existing), "BUDGET")
                    }
                }
            ]
        }, ct);
    }

    public static string BudgetPk(Guid id) => $"BUDGET#{id}";

    public static string BudgetUniquePk(Budget budget) => UniquePk(budget);

    internal static Dictionary<string, AttributeValue> ToItem(Budget budget)
    {
        var item = new Dictionary<string, AttributeValue>
        {
            ["PK"] = new(BudgetPk(budget.Id)),
            ["SK"] = new("PROFILE"),
            ["EntityType"] = new("Budget"),
            ["Id"] = new(budget.Id.ToString()),
            ["UserId"] = new(budget.UserId.ToString()),
            ["Category"] = new(budget.Category),
            ["MonthlyLimit"] = NumberValue(budget.MonthlyLimit),
            ["CurrencyCode"] = new(budget.CurrencyCode),
            ["Scope"] = new(budget.Scope.ToString()),
            ["GSI1PK"] = new(UserRepository.UserPk(budget.UserId)),
            ["GSI1SK"] = new($"BUDGET#{NormalizeKeyPart(budget.Category)}#{budget.Id}")
        };

        AddIfNotNull(item, "FamilySpaceId", budget.FamilySpaceId);
        AddIfNotNull(item, "SharedAt", budget.SharedAt);
        AddIfNotNull(item, "SharedByUserId", budget.SharedByUserId);

        if (budget.Scope == RecordScope.Family && budget.FamilySpaceId.HasValue)
        {
            item["GSI2PK"] = new(FamilySpaceRepository.FamilyPk(budget.FamilySpaceId.Value));
            item["GSI2SK"] = new($"BUDGET#{NormalizeKeyPart(budget.Category)}#{budget.Id}");
        }

        return item;
    }

    internal static Budget FromItem(Dictionary<string, AttributeValue> item) => new()
    {
        Id = Guid.Parse(item["Id"].S),
        UserId = Guid.Parse(item["UserId"].S),
        Category = item["Category"].S,
        MonthlyLimit = GetDecimal(item, "MonthlyLimit"),
        CurrencyCode = item.TryGetValue("CurrencyCode", out var currency) ? currency.S : "USD",
        Scope = item.TryGetValue("Scope", out var scope) ? Enum.Parse<RecordScope>(scope.S) : RecordScope.Personal,
        FamilySpaceId = GetOptionalGuid(item, "FamilySpaceId"),
        SharedAt = GetOptionalDateTime(item, "SharedAt"),
        SharedByUserId = GetOptionalGuid(item, "SharedByUserId")
    };

    private static Dictionary<string, AttributeValue> UniqueSentinel(Budget budget) => new()
    {
        ["PK"] = new(UniquePk(budget)),
        ["SK"] = new("BUDGET"),
        ["EntityType"] = new("BudgetUnique"),
        ["BudgetId"] = new(budget.Id.ToString())
    };

    private static string UniquePk(Budget budget)
    {
        var owner = budget.Scope == RecordScope.Family
            ? budget.FamilySpaceId?.ToString() ?? "missing-family"
            : budget.UserId.ToString();
        return $"BUDGET_UNIQUE#{budget.Scope}#{owner}#{NormalizeKeyPart(budget.Category)}";
    }

    private static InvalidOperationException DuplicateBudgetException(Exception inner) =>
        new("A budget for that category already exists.", inner);
}
