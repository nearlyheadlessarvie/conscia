using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Conscia.Infrastructure.Repositories;

namespace Conscia.Tests.Unit.Infrastructure;

public class ReceiptRepositoryTests : EfCoreTestBase
{
    private readonly ReceiptRepository _repo;

    public ReceiptRepositoryTests() => _repo = new ReceiptRepository(Db);

    [Fact]
    public async Task Add_CreatesReceipt()
    {
        var receipt = new Receipt
        {
            Id = Guid.NewGuid(),
            TransactionId = Guid.NewGuid(),
            S3Key = "receipts/test.jpg",
            Status = ReceiptStatus.Pending
        };

        var result = await _repo.AddAsync(receipt);

        Assert.Equal(receipt.Id, result.Id);
        Assert.Equal(ReceiptStatus.Pending, result.Status);
    }

    [Fact]
    public async Task GetByTransactionId_ReturnsCorrectReceipt()
    {
        var txnId = Guid.NewGuid();
        await _repo.AddAsync(new Receipt { Id = Guid.NewGuid(), TransactionId = txnId, S3Key = "receipts/a.jpg" });
        await _repo.AddAsync(new Receipt { Id = Guid.NewGuid(), TransactionId = Guid.NewGuid(), S3Key = "receipts/b.jpg" });

        var found = await _repo.GetByTransactionIdAsync(txnId);

        Assert.NotNull(found);
        Assert.Equal(txnId, found.TransactionId);
    }

    [Fact]
    public async Task UpdateStatus_ChangesStatus()
    {
        var receipt = new Receipt { Id = Guid.NewGuid(), TransactionId = Guid.NewGuid(), S3Key = "receipts/c.jpg", Status = ReceiptStatus.Pending };
        await _repo.AddAsync(receipt);

        receipt.Status = ReceiptStatus.Confirmed;
        await _repo.UpdateAsync(receipt);

        Db.ChangeTracker.Clear();
        var found = await _repo.GetByIdAsync(receipt.Id);
        Assert.Equal(ReceiptStatus.Confirmed, found!.Status);
    }

    [Fact]
    public async Task Update_ModifiesReceipt()
    {
        var receipt = new Receipt { Id = Guid.NewGuid(), TransactionId = Guid.NewGuid(), S3Key = "receipts/d.jpg" };
        await _repo.AddAsync(receipt);

        receipt.ExtractedData = "{\"merchant\":\"Store\"}";
        receipt.OcrConfidence = 0.95;
        await _repo.UpdateAsync(receipt);

        var found = await _repo.GetByIdAsync(receipt.Id);
        Assert.Equal("{\"merchant\":\"Store\"}", found!.ExtractedData);
        Assert.Equal(0.95, found.OcrConfidence);
    }
}
