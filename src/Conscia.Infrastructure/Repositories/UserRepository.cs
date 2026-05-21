using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.Model;
using Conscia.Application.Interfaces;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using System.Globalization;

namespace Conscia.Infrastructure.Repositories;

public class UserRepository : DynamoRepository, IUserRepository
{
    private const string TableName = "ControlPlane";

    public UserRepository(IAmazonDynamoDB dynamo) : base(dynamo)
    {
    }

    public async Task<User?> GetByIdAsync(Guid id, CancellationToken ct = default)
    {
        var response = await Dynamo.GetItemAsync(new GetItemRequest
        {
            TableName = TableName,
            Key = Key(UserPk(id), "PROFILE")
        }, ct);

        return IsMissingItem(response.Item)
            ? null
            : FromUserItem(response.Item);
    }

    public async Task<User?> GetByProviderAsync(AuthProvider provider, string providerSub, CancellationToken ct = default)
    {
        var response = await Dynamo.GetItemAsync(new GetItemRequest
        {
            TableName = TableName,
            Key = Key(IdentityPk(provider, providerSub), "USER")
        }, ct);

        if (IsMissingItem(response.Item) ||
            !response.Item.TryGetValue("UserId", out var userId))
            return null;

        return Guid.TryParse(userId.S, out var parsed)
            ? await GetByIdAsync(parsed, ct)
            : null;
    }

    public async Task<User?> GetByEmailAsync(string email, CancellationToken ct = default)
    {
        var response = await Dynamo.GetItemAsync(new GetItemRequest
        {
            TableName = TableName,
            Key = Key(EmailPk(email), "USER")
        }, ct);

        if (IsMissingItem(response.Item) ||
            !response.Item.TryGetValue("UserId", out var userId))
            return null;

        return Guid.TryParse(userId.S, out var parsed)
            ? await GetByIdAsync(parsed, ct)
            : null;
    }

    public async Task<IReadOnlyList<UserIdentity>> GetIdentitiesByUserAsync(Guid userId, CancellationToken ct = default)
    {
        var response = await Dynamo.QueryAsync(new QueryRequest
        {
            TableName = TableName,
            KeyConditionExpression = "PK = :pk AND begins_with(SK, :prefix)",
            ExpressionAttributeValues = new Dictionary<string, AttributeValue>
            {
                [":pk"] = new(UserPk(userId)),
                [":prefix"] = new("IDENTITY#")
            }
        }, ct);

        return Items(response)
            .Select(FromIdentityItem)
            .ToList();
    }

    public async Task<User> AddAsync(User user, CancellationToken ct = default)
    {
        user.Email = NormalizeEmail(user.Email);

        await Dynamo.TransactWriteItemsAsync(new TransactWriteItemsRequest
        {
            TransactItems =
            [
                new()
                {
                    Put = new Put
                    {
                        TableName = TableName,
                        Item = ToUserItem(user),
                        ConditionExpression = "attribute_not_exists(PK)"
                    }
                },
                new()
                {
                    Put = new Put
                    {
                        TableName = TableName,
                        Item = EmailSentinel(user),
                        ConditionExpression = "attribute_not_exists(PK)"
                    }
                }
            ]
        }, ct);

        return user;
    }

    public async Task<User> UpdateAsync(User user, CancellationToken ct = default)
    {
        user.Email = NormalizeEmail(user.Email);
        var existing = await GetByIdAsync(user.Id, ct);

        if (existing is not null &&
            !string.Equals(NormalizeEmail(existing.Email), user.Email, StringComparison.Ordinal))
        {
            await Dynamo.TransactWriteItemsAsync(new TransactWriteItemsRequest
            {
                TransactItems =
                [
                    new()
                    {
                        Delete = new Delete
                        {
                            TableName = TableName,
                            Key = Key(EmailPk(existing.Email), "USER")
                        }
                    },
                    new()
                    {
                        Put = new Put
                        {
                            TableName = TableName,
                            Item = EmailSentinel(user),
                            ConditionExpression = "attribute_not_exists(PK)"
                        }
                    },
                    new()
                    {
                        Put = new Put
                        {
                            TableName = TableName,
                            Item = ToUserItem(user)
                        }
                    }
                ]
            }, ct);
        }
        else
        {
            await Dynamo.PutItemAsync(new PutItemRequest
            {
                TableName = TableName,
                Item = ToUserItem(user)
            }, ct);
        }

        return user;
    }

    public async Task DeleteAsync(Guid id, CancellationToken ct = default)
    {
        var response = await Dynamo.QueryAsync(new QueryRequest
        {
            TableName = TableName,
            KeyConditionExpression = "PK = :pk",
            ExpressionAttributeValues = new Dictionary<string, AttributeValue>
            {
                [":pk"] = new(UserPk(id))
            }
        }, ct);

        if (Items(response).Count == 0)
            return;

        var deletes = new List<WriteRequest>();
        foreach (var item in Items(response))
        {
            deletes.Add(DeleteRequest(item["PK"].S, item["SK"].S));

            if (item["SK"].S == "PROFILE" && item.TryGetValue("Email", out var email))
                deletes.Add(DeleteRequest(EmailPk(email.S), "USER"));

            if (item["SK"].S.StartsWith("IDENTITY#", StringComparison.Ordinal)
                && item.TryGetValue("Provider", out var provider)
                && item.TryGetValue("ProviderSub", out var providerSub))
            {
                deletes.Add(DeleteRequest(IdentityPk(Enum.Parse<AuthProvider>(provider.S), providerSub.S), "USER"));
            }

            if (item["SK"].S.StartsWith("SUBSCRIPTION#", StringComparison.Ordinal)
                && item.TryGetValue("OriginalTransactionId", out var originalTransactionId))
            {
                deletes.Add(DeleteRequest(SubscriptionOriginalPk(originalTransactionId.S), "SUBSCRIPTION"));
            }
        }

        foreach (var batch in deletes.Chunk(25))
        {
            await Dynamo.BatchWriteItemAsync(new BatchWriteItemRequest
            {
                RequestItems = new Dictionary<string, List<WriteRequest>>
                {
                    [TableName] = batch.ToList()
                }
            }, ct);
        }
    }

    public async Task<UserIdentity> AddIdentityAsync(UserIdentity identity, CancellationToken ct = default)
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
                        Item = ToIdentityItem(identity),
                        ConditionExpression = "attribute_not_exists(PK) AND attribute_not_exists(SK)"
                    }
                },
                new()
                {
                    Put = new Put
                    {
                        TableName = TableName,
                        Item = IdentitySentinel(identity),
                        ConditionExpression = "attribute_not_exists(PK)"
                    }
                }
            ]
        }, ct);

        return identity;
    }

    public async Task<UserIdentity> UpdateIdentityAsync(UserIdentity identity, CancellationToken ct = default)
    {
        await Dynamo.PutItemAsync(new PutItemRequest
        {
            TableName = TableName,
            Item = ToIdentityItem(identity)
        }, ct);

        return identity;
    }

    public static string UserPk(Guid userId) => $"USER#{userId}";
    public static string EmailPk(string email) => $"EMAIL#{NormalizeEmail(email)}";
    public static string IdentityPk(AuthProvider provider, string providerSub) =>
        $"IDENTITY#{provider}#{NormalizeKeyPart(providerSub)}";
    public static string SubscriptionOriginalPk(string originalTransactionId) =>
        $"SUBSCRIPTION_TX#{NormalizeKeyPart(originalTransactionId)}";

    internal static Dictionary<string, AttributeValue> ToUserItem(User user)
    {
        var item = new Dictionary<string, AttributeValue>
        {
            ["PK"] = new(UserPk(user.Id)),
            ["SK"] = new("PROFILE"),
            ["EntityType"] = new("User"),
            ["Id"] = new(user.Id.ToString()),
            ["Email"] = new(NormalizeEmail(user.Email)),
            ["EmailConfirmed"] = BoolValue(user.EmailConfirmed),
            ["PreferredCurrency"] = new(user.PreferredCurrency),
            ["Locale"] = new(user.Locale),
            ["CreatedAt"] = new(user.CreatedAt.ToString("O", CultureInfo.InvariantCulture)),
            ["HasCompletedOnboarding"] = BoolValue(user.HasCompletedOnboarding),
            ["LocationSuggestionsEnabled"] = BoolValue(user.LocationSuggestionsEnabled),
            ["AiPersonalityIntensity"] = new(user.AiPersonalityIntensity)
        };

        AddIfNotNull(item, "DisplayName", user.DisplayName);
        AddIfNotNull(item, "ProfilePictureKey", user.ProfilePictureKey);
        AddIfNotNull(item, "SpendingPersonality", user.SpendingPersonality);
        AddIfNotNull(item, "IncomeRange", user.IncomeRange);
        AddIfNotNull(item, "OccupationType", user.OccupationType);
        AddIfNotNull(item, "HouseholdSize", user.HouseholdSize);

        return item;
    }

    internal static User FromUserItem(Dictionary<string, AttributeValue> item) => new()
    {
        Id = Guid.Parse(item["Id"].S),
        Email = item["Email"].S,
        EmailConfirmed = GetBool(item, "EmailConfirmed", true),
        DisplayName = GetOptionalString(item, "DisplayName"),
        ProfilePictureKey = GetOptionalString(item, "ProfilePictureKey"),
        PreferredCurrency = item.TryGetValue("PreferredCurrency", out var currency) ? currency.S : "USD",
        Locale = item.TryGetValue("Locale", out var locale) ? locale.S : "en-US",
        CreatedAt = item.TryGetValue("CreatedAt", out var createdAt)
            ? DateTime.Parse(createdAt.S, CultureInfo.InvariantCulture, DateTimeStyles.RoundtripKind)
            : DateTime.UtcNow,
        SpendingPersonality = GetOptionalString(item, "SpendingPersonality"),
        IncomeRange = GetOptionalString(item, "IncomeRange"),
        OccupationType = GetOptionalString(item, "OccupationType"),
        HouseholdSize = GetOptionalString(item, "HouseholdSize"),
        HasCompletedOnboarding = GetBool(item, "HasCompletedOnboarding"),
        LocationSuggestionsEnabled = GetBool(item, "LocationSuggestionsEnabled"),
        AiPersonalityIntensity = item.TryGetValue("AiPersonalityIntensity", out var intensity)
            ? intensity.S
            : "balanced"
    };

    private static Dictionary<string, AttributeValue> EmailSentinel(User user) => new()
    {
        ["PK"] = new(EmailPk(user.Email)),
        ["SK"] = new("USER"),
        ["EntityType"] = new("UserEmail"),
        ["UserId"] = new(user.Id.ToString())
    };

    private static Dictionary<string, AttributeValue> ToIdentityItem(UserIdentity identity) => new()
    {
        ["PK"] = new(UserPk(identity.UserId)),
        ["SK"] = new($"IDENTITY#{identity.Provider}#{NormalizeKeyPart(identity.ProviderSub)}"),
        ["EntityType"] = new("UserIdentity"),
        ["Id"] = new(identity.Id.ToString()),
        ["UserId"] = new(identity.UserId.ToString()),
        ["Provider"] = new(identity.Provider.ToString()),
        ["ProviderSub"] = new(identity.ProviderSub),
        ["Role"] = new(identity.Role.ToString()),
        ["CreatedAt"] = new(identity.CreatedAt.ToString("O", CultureInfo.InvariantCulture))
    };

    private static UserIdentity FromIdentityItem(Dictionary<string, AttributeValue> item) => new()
    {
        Id = Guid.Parse(item["Id"].S),
        UserId = Guid.Parse(item["UserId"].S),
        Provider = Enum.Parse<AuthProvider>(item["Provider"].S),
        ProviderSub = item["ProviderSub"].S,
        Role = item.TryGetValue("Role", out var role)
            ? Enum.Parse<UserIdentityRole>(role.S)
            : UserIdentityRole.Member,
        CreatedAt = DateTime.Parse(item["CreatedAt"].S, CultureInfo.InvariantCulture, DateTimeStyles.RoundtripKind)
    };

    private static Dictionary<string, AttributeValue> IdentitySentinel(UserIdentity identity) => new()
    {
        ["PK"] = new(IdentityPk(identity.Provider, identity.ProviderSub)),
        ["SK"] = new("USER"),
        ["EntityType"] = new("UserIdentityLookup"),
        ["UserId"] = new(identity.UserId.ToString()),
        ["IdentityId"] = new(identity.Id.ToString())
    };

    private static WriteRequest DeleteRequest(string pk, string sk) => new()
    {
        DeleteRequest = new DeleteRequest
        {
            Key = Key(pk, sk)
        }
    };

    private static string NormalizeEmail(string email) => email.Trim().ToLowerInvariant();
}
