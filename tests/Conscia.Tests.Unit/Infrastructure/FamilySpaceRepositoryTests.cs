using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.Model;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Conscia.Infrastructure.Repositories;
using Moq;

namespace Conscia.Tests.Unit.Infrastructure;

public class FamilySpaceRepositoryTests
{
    [Fact]
    public async Task GetMembershipByUserIdAsync_WhenLookupItemIsNull_ReturnsNull()
    {
        var dynamoMock = new Mock<IAmazonDynamoDB>();
        dynamoMock
            .Setup(d => d.GetItemAsync(It.IsAny<GetItemRequest>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new GetItemResponse { Item = null });

        var result = await new FamilySpaceRepository(dynamoMock.Object)
            .GetMembershipByUserIdAsync(Guid.NewGuid(), CancellationToken.None);

        Assert.Null(result);
    }

    [Fact]
    public async Task TransferOwnershipAsync_WritesBothMemberRoleChangesAtomically()
    {
        var familySpaceId = Guid.NewGuid();
        var oldOwner = new FamilyMember
        {
            Id = Guid.NewGuid(),
            UserId = Guid.NewGuid(),
            FamilySpaceId = familySpaceId,
            Role = FamilyMemberRole.Contributor,
            JoinedAt = new DateTime(2026, 5, 1, 0, 0, 0, DateTimeKind.Utc)
        };
        var newOwner = new FamilyMember
        {
            Id = Guid.NewGuid(),
            UserId = Guid.NewGuid(),
            FamilySpaceId = familySpaceId,
            Role = FamilyMemberRole.Owner,
            JoinedAt = new DateTime(2026, 5, 2, 0, 0, 0, DateTimeKind.Utc)
        };
        var dynamoMock = new Mock<IAmazonDynamoDB>();
        TransactWriteItemsRequest? captured = null;
        dynamoMock
            .Setup(d => d.TransactWriteItemsAsync(It.IsAny<TransactWriteItemsRequest>(), It.IsAny<CancellationToken>()))
            .Callback<TransactWriteItemsRequest, CancellationToken>((request, _) => captured = request)
            .ReturnsAsync(new TransactWriteItemsResponse());

        await new FamilySpaceRepository(dynamoMock.Object)
            .TransferOwnershipAsync(oldOwner, newOwner, CancellationToken.None);

        Assert.NotNull(captured);
        Assert.Equal(2, captured!.TransactItems.Count);
        Assert.All(captured.TransactItems, item => Assert.NotNull(item.Put));
        Assert.Contains(captured.TransactItems, item =>
            item.Put.Item["Id"].S == oldOwner.Id.ToString() &&
            item.Put.Item["Role"].S == FamilyMemberRole.Contributor.ToString());
        Assert.Contains(captured.TransactItems, item =>
            item.Put.Item["Id"].S == newOwner.Id.ToString() &&
            item.Put.Item["Role"].S == FamilyMemberRole.Owner.ToString());
    }
}
