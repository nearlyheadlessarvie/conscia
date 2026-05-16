using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.Model;
using Conscia.Application.Interfaces;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using System.Globalization;

namespace Conscia.Infrastructure.Repositories;

public class FamilySpaceRepository : DynamoRepository, IFamilySpaceRepository
{
    private const string TableName = "ControlPlane";

    public FamilySpaceRepository(IAmazonDynamoDB dynamo) : base(dynamo)
    {
    }

    public async Task<FamilySpace?> GetByIdAsync(Guid familySpaceId, CancellationToken ct = default)
    {
        var response = await Dynamo.GetItemAsync(new GetItemRequest
        {
            TableName = TableName,
            Key = Key(FamilyPk(familySpaceId), "PROFILE")
        }, ct);

        return response.Item.Count == 0 ? null : FromSpaceItem(response.Item);
    }

    public async Task<FamilyMember?> GetMembershipByUserIdAsync(Guid userId, CancellationToken ct = default)
    {
        var response = await Dynamo.GetItemAsync(new GetItemRequest
        {
            TableName = TableName,
            Key = Key(MemberUserPk(userId), "MEMBERSHIP")
        }, ct);

        if (response.Item.Count == 0 ||
            !response.Item.TryGetValue("FamilySpaceId", out var familySpaceId) ||
            !response.Item.TryGetValue("MemberId", out var memberId))
        {
            return null;
        }

        var member = await GetMemberByIdAsync(Guid.Parse(familySpaceId.S), Guid.Parse(memberId.S), ct);
        return member;
    }

    public async Task<IReadOnlyList<FamilyMember>> ListMembersAsync(Guid familySpaceId, CancellationToken ct = default)
    {
        var response = await Dynamo.QueryAsync(new QueryRequest
        {
            TableName = TableName,
            KeyConditionExpression = "PK = :pk AND begins_with(SK, :prefix)",
            ExpressionAttributeValues = new Dictionary<string, AttributeValue>
            {
                [":pk"] = new(FamilyPk(familySpaceId)),
                [":prefix"] = new("MEMBER#")
            }
        }, ct);

        return response.Items
            .Select(FromMemberItem)
            .OrderBy(member => member.JoinedAt)
            .ToList();
    }

    public async Task<FamilySpace> CreateWithOwnerAsync(FamilySpace space, FamilyMember owner, CancellationToken ct = default)
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
                        Item = ToSpaceItem(space),
                        ConditionExpression = "attribute_not_exists(PK)"
                    }
                },
                new()
                {
                    Put = new Put
                    {
                        TableName = TableName,
                        Item = ToMemberItem(owner),
                        ConditionExpression = "attribute_not_exists(PK) AND attribute_not_exists(SK)"
                    }
                },
                new()
                {
                    Put = new Put
                    {
                        TableName = TableName,
                        Item = MemberUserSentinel(owner),
                        ConditionExpression = "attribute_not_exists(PK)"
                    }
                }
            ]
        }, ct);

        return space;
    }

    public async Task<FamilySpace> UpdateAsync(FamilySpace space, CancellationToken ct = default)
    {
        await Dynamo.PutItemAsync(new PutItemRequest
        {
            TableName = TableName,
            Item = ToSpaceItem(space)
        }, ct);

        return space;
    }

    public async Task<FamilyInvite> AddInviteAsync(FamilyInvite invite, CancellationToken ct = default)
    {
        invite.Email = NormalizeEmail(invite.Email);
        await Dynamo.PutItemAsync(new PutItemRequest
        {
            TableName = TableName,
            Item = ToInviteItem(invite),
            ConditionExpression = "attribute_not_exists(PK)"
        }, ct);

        return invite;
    }

    public async Task<FamilyInvite?> GetInviteAsync(Guid inviteId, CancellationToken ct = default)
    {
        var response = await Dynamo.GetItemAsync(new GetItemRequest
        {
            TableName = TableName,
            Key = Key(InvitePk(inviteId), "PROFILE")
        }, ct);

        return response.Item.Count == 0 ? null : FromInviteItem(response.Item);
    }

    public async Task<FamilyInvite?> GetActiveInviteByEmailAsync(string normalizedEmail, CancellationToken ct = default)
    {
        var invites = await ListActiveInvitesByEmailAsync(normalizedEmail, ct);
        return invites.OrderByDescending(invite => invite.CreatedAt).FirstOrDefault();
    }

    public async Task<IReadOnlyList<FamilyInvite>> ListActiveInvitesByEmailAsync(string normalizedEmail, CancellationToken ct = default)
    {
        var response = await Dynamo.QueryAsync(new QueryRequest
        {
            TableName = TableName,
            IndexName = "GSI1",
            KeyConditionExpression = "GSI1PK = :pk",
            ExpressionAttributeValues = new Dictionary<string, AttributeValue>
            {
                [":pk"] = new(InviteEmailPk(normalizedEmail))
            }
        }, ct);

        return response.Items.Select(FromInviteItem).Where(IsActiveInvite).OrderByDescending(i => i.CreatedAt).ToList();
    }

    public async Task<IReadOnlyList<FamilyInvite>> ListActiveInvitesByFamilySpaceAsync(Guid familySpaceId, CancellationToken ct = default)
    {
        var response = await Dynamo.QueryAsync(new QueryRequest
        {
            TableName = TableName,
            IndexName = "GSI2",
            KeyConditionExpression = "GSI2PK = :pk",
            ExpressionAttributeValues = new Dictionary<string, AttributeValue>
            {
                [":pk"] = new(FamilyPk(familySpaceId))
            }
        }, ct);

        return response.Items
            .Where(item => item.TryGetValue("EntityType", out var type) && type.S == "FamilyInvite")
            .Select(FromInviteItem)
            .Where(IsActiveInvite)
            .OrderByDescending(i => i.CreatedAt)
            .ToList();
    }

    public async Task<FamilyMember> AddMemberAsync(FamilyMember member, CancellationToken ct = default)
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
                        Item = ToMemberItem(member),
                        ConditionExpression = "attribute_not_exists(PK) AND attribute_not_exists(SK)"
                    }
                },
                new()
                {
                    Put = new Put
                    {
                        TableName = TableName,
                        Item = MemberUserSentinel(member),
                        ConditionExpression = "attribute_not_exists(PK)"
                    }
                }
            ]
        }, ct);

        return member;
    }

    public async Task UpdateInviteAsync(FamilyInvite invite, CancellationToken ct = default)
    {
        invite.Email = NormalizeEmail(invite.Email);
        await Dynamo.PutItemAsync(new PutItemRequest
        {
            TableName = TableName,
            Item = ToInviteItem(invite)
        }, ct);
    }

    public async Task DeleteInviteAsync(Guid inviteId, CancellationToken ct = default)
    {
        await Dynamo.DeleteItemAsync(new DeleteItemRequest
        {
            TableName = TableName,
            Key = Key(InvitePk(inviteId), "PROFILE")
        }, ct);
    }

    public async Task UpdateMemberAsync(FamilyMember member, CancellationToken ct = default)
    {
        await Dynamo.PutItemAsync(new PutItemRequest
        {
            TableName = TableName,
            Item = ToMemberItem(member)
        }, ct);
    }

    public async Task DeleteMemberAsync(Guid memberId, CancellationToken ct = default)
    {
        var member = await FindMemberByIdAsync(memberId, ct);
        if (member is null)
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
                        Key = Key(FamilyPk(member.FamilySpaceId), MemberSk(member))
                    }
                },
                new()
                {
                    Delete = new Delete
                    {
                        TableName = TableName,
                        Key = Key(MemberUserPk(member.UserId), "MEMBERSHIP")
                    }
                }
            ]
        }, ct);
    }

    public static string FamilyPk(Guid familySpaceId) => $"FAMILY#{familySpaceId}";
    private static string MemberUserPk(Guid userId) => $"MEMBER_USER#{userId}";
    private static string InvitePk(Guid inviteId) => $"INVITE#{inviteId}";
    private static string InviteEmailPk(string email) => $"INVITE_EMAIL#{NormalizeEmail(email)}";
    private static string MemberSk(FamilyMember member) => $"MEMBER#{member.JoinedAt:O}#{member.Id}";

    private static Dictionary<string, AttributeValue> ToSpaceItem(FamilySpace space)
    {
        var item = new Dictionary<string, AttributeValue>
        {
            ["PK"] = new(FamilyPk(space.Id)),
            ["SK"] = new("PROFILE"),
            ["EntityType"] = new("FamilySpace"),
            ["Id"] = new(space.Id.ToString()),
            ["Name"] = new(space.Name),
            ["CurrencyCode"] = new(space.CurrencyCode),
            ["CreatedByUserId"] = new(space.CreatedByUserId.ToString()),
            ["CreatedAt"] = new(space.CreatedAt.ToString("O", CultureInfo.InvariantCulture)),
            ["IsReadOnly"] = BoolValue(space.IsReadOnly)
        };

        AddIfNotNull(item, "PremiumGraceEndsAt", space.PremiumGraceEndsAt);
        return item;
    }

    private static FamilySpace FromSpaceItem(Dictionary<string, AttributeValue> item) => new()
    {
        Id = Guid.Parse(item["Id"].S),
        Name = item["Name"].S,
        CurrencyCode = item.TryGetValue("CurrencyCode", out var currency) ? currency.S : "USD",
        CreatedByUserId = Guid.Parse(item["CreatedByUserId"].S),
        CreatedAt = DateTime.Parse(item["CreatedAt"].S, CultureInfo.InvariantCulture, DateTimeStyles.RoundtripKind),
        PremiumGraceEndsAt = GetOptionalDateTime(item, "PremiumGraceEndsAt"),
        IsReadOnly = GetBool(item, "IsReadOnly")
    };

    private static Dictionary<string, AttributeValue> ToMemberItem(FamilyMember member) => new()
    {
        ["PK"] = new(FamilyPk(member.FamilySpaceId)),
        ["SK"] = new(MemberSk(member)),
        ["EntityType"] = new("FamilyMember"),
        ["Id"] = new(member.Id.ToString()),
        ["FamilySpaceId"] = new(member.FamilySpaceId.ToString()),
        ["UserId"] = new(member.UserId.ToString()),
        ["Role"] = new(member.Role.ToString()),
        ["JoinedAt"] = new(member.JoinedAt.ToString("O", CultureInfo.InvariantCulture))
    };

    private static Dictionary<string, AttributeValue> MemberUserSentinel(FamilyMember member) => new()
    {
        ["PK"] = new(MemberUserPk(member.UserId)),
        ["SK"] = new("MEMBERSHIP"),
        ["EntityType"] = new("FamilyMemberLookup"),
        ["FamilySpaceId"] = new(member.FamilySpaceId.ToString()),
        ["MemberId"] = new(member.Id.ToString())
    };

    private static FamilyMember FromMemberItem(Dictionary<string, AttributeValue> item) => new()
    {
        Id = Guid.Parse(item["Id"].S),
        FamilySpaceId = Guid.Parse(item["FamilySpaceId"].S),
        UserId = Guid.Parse(item["UserId"].S),
        Role = Enum.Parse<FamilyMemberRole>(item["Role"].S),
        JoinedAt = DateTime.Parse(item["JoinedAt"].S, CultureInfo.InvariantCulture, DateTimeStyles.RoundtripKind)
    };

    private static Dictionary<string, AttributeValue> ToInviteItem(FamilyInvite invite)
    {
        var item = new Dictionary<string, AttributeValue>
        {
            ["PK"] = new(InvitePk(invite.Id)),
            ["SK"] = new("PROFILE"),
            ["EntityType"] = new("FamilyInvite"),
            ["Id"] = new(invite.Id.ToString()),
            ["FamilySpaceId"] = new(invite.FamilySpaceId.ToString()),
            ["Email"] = new(NormalizeEmail(invite.Email)),
            ["Role"] = new(invite.Role.ToString()),
            ["InvitedByUserId"] = new(invite.InvitedByUserId.ToString()),
            ["CreatedAt"] = new(invite.CreatedAt.ToString("O", CultureInfo.InvariantCulture)),
            ["ExpiresAt"] = new(invite.ExpiresAt.ToString("O", CultureInfo.InvariantCulture)),
            ["GSI1PK"] = new(InviteEmailPk(invite.Email)),
            ["GSI1SK"] = new($"INVITE#{invite.CreatedAt:O}#{invite.Id}"),
            ["GSI2PK"] = new(FamilyPk(invite.FamilySpaceId)),
            ["GSI2SK"] = new($"INVITE#{invite.CreatedAt:O}#{invite.Id}")
        };

        AddIfNotNull(item, "AcceptedAt", invite.AcceptedAt);
        AddIfNotNull(item, "DeclinedAt", invite.DeclinedAt);
        return item;
    }

    private static FamilyInvite FromInviteItem(Dictionary<string, AttributeValue> item) => new()
    {
        Id = Guid.Parse(item["Id"].S),
        FamilySpaceId = Guid.Parse(item["FamilySpaceId"].S),
        Email = item["Email"].S,
        Role = Enum.Parse<FamilyMemberRole>(item["Role"].S),
        InvitedByUserId = Guid.Parse(item["InvitedByUserId"].S),
        CreatedAt = DateTime.Parse(item["CreatedAt"].S, CultureInfo.InvariantCulture, DateTimeStyles.RoundtripKind),
        ExpiresAt = DateTime.Parse(item["ExpiresAt"].S, CultureInfo.InvariantCulture, DateTimeStyles.RoundtripKind),
        AcceptedAt = GetOptionalDateTime(item, "AcceptedAt"),
        DeclinedAt = GetOptionalDateTime(item, "DeclinedAt")
    };

    private async Task<FamilyMember?> GetMemberByIdAsync(Guid familySpaceId, Guid memberId, CancellationToken ct)
    {
        var members = await ListMembersAsync(familySpaceId, ct);
        return members.FirstOrDefault(member => member.Id == memberId);
    }

    private async Task<FamilyMember?> FindMemberByIdAsync(Guid memberId, CancellationToken ct)
    {
        var response = await Dynamo.ScanAsync(new ScanRequest
        {
            TableName = TableName,
            FilterExpression = "EntityType = :type AND Id = :id",
            ExpressionAttributeValues = new Dictionary<string, AttributeValue>
            {
                [":type"] = new("FamilyMember"),
                [":id"] = new(memberId.ToString())
            }
        }, ct);

        return response.Items.Count == 0 ? null : FromMemberItem(response.Items[0]);
    }

    private static bool IsActiveInvite(FamilyInvite invite)
    {
        var now = DateTime.UtcNow;
        return invite.AcceptedAt is null && invite.DeclinedAt is null && invite.ExpiresAt > now;
    }

    private static string NormalizeEmail(string email) => email.Trim().ToLowerInvariant();
}
