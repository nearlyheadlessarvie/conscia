using System.Text.Json;
using Conscia.Application.DTOs;
using Conscia.Application.Interfaces;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Conscia.Domain.ValueObjects;
using Conscia.Infrastructure.Services;
using Microsoft.Extensions.Logging.Abstractions;
using Moq;

namespace Conscia.Tests.Unit.Infrastructure;

public class ReceiptServiceTests
{
    private readonly Mock<IReceiptRepository> _receipts = new();
    private readonly Mock<ITransactionService> _transactions = new();
    private readonly Mock<IS3StorageService> _storage = new();
    private readonly Mock<IOcrService> _ocr = new();

    [Fact]
    public async Task ScanAsync_StoresParsedReceiptDataInsteadOfSampleFallback()
    {
        var userId = Guid.NewGuid();
        _ocr.SetupGet(o => o.IsConfigured).Returns(true);
        _ocr.Setup(o => o.ExtractTextAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync("Merchant: Real Cafe\nTotal: 42.50");
        _ocr.Setup(o => o.ParseReceiptTextAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new ReceiptScanResultDto
            {
                Merchant = "Real Cafe",
                Total = 42.50m,
                CurrencyCode = "PHP",
                Date = new DateTime(2026, 5, 19, 0, 0, 0, DateTimeKind.Utc),
                Confidence = 0.73,
                LineItems = new List<LineItemDto>
                {
                    new() { Description = "Latte", Amount = 42.50m }
                }
            });

        Receipt? stored = null;
        _receipts.Setup(r => r.AddAsync(It.IsAny<Receipt>(), It.IsAny<CancellationToken>()))
            .Callback<Receipt, CancellationToken>((receipt, _) => stored = receipt)
            .ReturnsAsync((Receipt receipt, CancellationToken _) => receipt);

        var service = CreateService();

        var result = await service.ScanAsync(
            userId,
            new MemoryStream([1, 2, 3]),
            "image/jpeg");

        Assert.Equal("Real Cafe", result.Merchant);
        Assert.Equal(42.50m, result.Total);
        Assert.Equal("PHP", result.CurrencyCode);
        Assert.NotNull(stored);
        Assert.Equal(userId, stored!.UserId);
        Assert.DoesNotContain("Sample Merchant", stored.ExtractedData);
        Assert.Contains("Real Cafe", stored.ExtractedData);
    }

    [Fact]
    public async Task ScanAsync_DoesNotInventUsdWhenOcrCannotInferCurrency()
    {
        var userId = Guid.NewGuid();
        _ocr.SetupGet(o => o.IsConfigured).Returns(true);
        _ocr.Setup(o => o.ExtractTextAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync("Total: 0");
        _ocr.Setup(o => o.ParseReceiptTextAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new ReceiptScanResultDto
            {
                Merchant = "Unknown Merchant",
                Total = 0m,
                CurrencyCode = null,
                Confidence = 0,
                LineItems = []
            });

        Receipt? stored = null;
        _receipts.Setup(r => r.AddAsync(It.IsAny<Receipt>(), It.IsAny<CancellationToken>()))
            .Callback<Receipt, CancellationToken>((receipt, _) => stored = receipt)
            .ReturnsAsync((Receipt receipt, CancellationToken _) => receipt);

        var service = CreateService();

        var result = await service.ScanAsync(
            userId,
            new MemoryStream([1, 2, 3]),
            "image/jpeg");

        Assert.Null(result.CurrencyCode);
        Assert.NotNull(stored);
        using var document = JsonDocument.Parse(stored!.ExtractedData!);
        Assert.True(document.RootElement.TryGetProperty("currencyCode", out var currency));
        Assert.Equal(JsonValueKind.Null, currency.ValueKind);
    }

    [Fact]
    public async Task ConfirmAsync_CreatesExpenseTransactionAndMarksReceiptConfirmed()
    {
        var userId = Guid.NewGuid();
        var receiptId = Guid.NewGuid();
        var transactionId = Guid.NewGuid();
        var receipt = new Receipt
        {
            Id = receiptId,
            UserId = userId,
            S3Key = "receipts/photo.jpg",
            Status = ReceiptStatus.ReviewRequired,
            ExtractedData = "{}"
        };

        _receipts.Setup(r => r.GetByIdAsync(receiptId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(receipt);
        _transactions.Setup(t => t.CreateAsync(
                userId,
                It.Is<CreateTransactionDto>(dto =>
                    dto.Type == TransactionType.Expense &&
                    dto.Amount == 29.99m &&
                    dto.CurrencyCode == "USD" &&
                    dto.Category == "Dining" &&
                    dto.Counterparty == "Corner Cafe"),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(new Transaction
            {
                Id = transactionId,
                UserId = userId,
                Type = TransactionType.Expense,
                Amount = new Money(29.99m, "USD"),
                Category = "Dining",
                Counterparty = "Corner Cafe",
                Date = new DateTime(2026, 5, 19, 0, 0, 0, DateTimeKind.Utc)
            });

        var service = CreateService();

        var result = await service.ConfirmAsync(
            userId,
            receiptId,
            new ConfirmReceiptRequest(
                "Corner Cafe",
                29.99m,
                "USD",
                "Dining",
                new DateTime(2026, 5, 19, 0, 0, 0, DateTimeKind.Utc)));

        Assert.Equal(transactionId, result.Id);
        Assert.Equal(ReceiptStatus.Confirmed, receipt.Status);
        Assert.Equal(transactionId, receipt.TransactionId);
        _receipts.Verify(r => r.UpdateAsync(receipt, It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task ConfirmAsync_RejectsReceiptOwnedByAnotherUser()
    {
        var receiptId = Guid.NewGuid();
        _receipts.Setup(r => r.GetByIdAsync(receiptId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new Receipt
            {
                Id = receiptId,
                UserId = Guid.NewGuid(),
                S3Key = "receipts/photo.jpg"
            });

        var service = CreateService();

        await Assert.ThrowsAsync<UnauthorizedAccessException>(() =>
            service.ConfirmAsync(
                Guid.NewGuid(),
                receiptId,
                new ConfirmReceiptRequest(
                    "Corner Cafe",
                    29.99m,
                    "USD",
                    "Dining",
                    DateTime.UtcNow)));
    }

    [Fact]
    public async Task ScanAsync_Throws_WhenOcrIsNotConfigured()
    {
        _ocr.SetupGet(o => o.IsConfigured).Returns(false);

        var service = CreateService();

        var ex = await Assert.ThrowsAsync<InvalidOperationException>(() =>
            service.ScanAsync(Guid.NewGuid(), new MemoryStream([1, 2, 3]), "image/jpeg"));

        Assert.Equal("Receipt scanning is not configured.", ex.Message);
        _storage.Verify(
            s => s.UploadAsync(It.IsAny<string>(), It.IsAny<Stream>(), It.IsAny<string>(), It.IsAny<CancellationToken>()),
            Times.Never);
    }

    private ReceiptService CreateService() =>
        new(
            _receipts.Object,
            _transactions.Object,
            _storage.Object,
            _ocr.Object,
            NullLogger<ReceiptService>.Instance);
}
