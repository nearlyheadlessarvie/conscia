using Conscia.Application.Interfaces;
using Moq;

namespace Conscia.Tests.Unit.Application;

public class PurchasePatternServiceTests
{
    private readonly Mock<IPurchasePatternRepository> _repoMock = new();
    private readonly Mock<ITransactionRepository> _txRepoMock = new();

    [Fact]
    public void Placeholder_CompilesOk() => Assert.True(true);
}
