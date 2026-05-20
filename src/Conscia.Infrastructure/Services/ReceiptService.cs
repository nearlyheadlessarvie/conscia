using System.Text.Json;
using Conscia.Application.DTOs;
using Conscia.Application.Interfaces;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Microsoft.Extensions.Logging;

namespace Conscia.Infrastructure.Services;

public class ReceiptService : IReceiptService
{
    private readonly IReceiptRepository _receipts;
    private readonly ITransactionService _transactions;
    private readonly IS3StorageService _storage;
    private readonly IOcrService _ocr;
    private readonly ILogger<ReceiptService> _logger;

    public ReceiptService(
        IReceiptRepository receipts,
        ITransactionService transactions,
        IS3StorageService storage,
        IOcrService ocr,
        ILogger<ReceiptService> logger)
    {
        _receipts = receipts;
        _transactions = transactions;
        _storage = storage;
        _ocr = ocr;
        _logger = logger;
    }

    public async Task<ReceiptScanResult> ScanAsync(
        Guid userId,
        Stream imageStream,
        string contentType = "image/jpeg",
        CancellationToken ct = default)
    {
        if (!_ocr.IsConfigured)
        {
            _logger.LogError("Receipt scanning attempted without OCR configuration");
            throw new InvalidOperationException("Receipt scanning is not configured.");
        }

        var receiptId = Guid.NewGuid();
        var s3Key = $"receipts/{userId}/{receiptId}{ExtensionFor(contentType)}";

        await _storage.UploadAsync(s3Key, imageStream, contentType, ct);

        var rawText = await _ocr.ExtractTextAsync(s3Key, ct);
        var parsed = await _ocr.ParseReceiptTextAsync(rawText, ct);
        var total = parsed.Total ?? 0m;
        var currencyCode = string.IsNullOrWhiteSpace(parsed.CurrencyCode)
            ? null
            : parsed.CurrencyCode.Trim().ToUpperInvariant();
        var lineItems = (parsed.LineItems ?? new List<LineItemDto>())
            .Select(item => new ReceiptLineItem(item.Description, item.Amount))
            .ToList();
        var needsReview =
            parsed.Confidence < 0.9 ||
            total <= 0 ||
            string.IsNullOrWhiteSpace(parsed.Merchant);

        var receipt = new Receipt
        {
            Id = receiptId,
            UserId = userId,
            S3Key = s3Key,
            OcrConfidence = parsed.Confidence,
            NeedsReview = needsReview,
            Status = needsReview ? ReceiptStatus.ReviewRequired : ReceiptStatus.Scanned,
            ExtractedData = SerializeExtractedData(parsed, total, currencyCode),
            CreatedAt = DateTime.UtcNow
        };

        await _receipts.AddAsync(receipt, ct);
        _logger.LogInformation("Stored receipt scan {ReceiptId} for user {UserId}", receiptId, userId);

        return new ReceiptScanResult(
            Id: receiptId,
            Merchant: parsed.Merchant,
            Total: total,
            CurrencyCode: currencyCode,
            Date: parsed.Date,
            Confidence: parsed.Confidence,
            LineItems: lineItems);
    }

    public async Task<object?> GetByIdAsync(Guid userId, Guid receiptId, CancellationToken ct = default)
    {
        var receipt = await _receipts.GetByIdAsync(receiptId, ct);
        if (receipt is null)
            return null;

        EnsureReceiptOwner(receipt, userId);

        return new
        {
            id = receipt.Id,
            status = receipt.Status.ToString(),
            ocrConfidence = receipt.OcrConfidence,
            needsReview = receipt.NeedsReview,
            extractedData = ParseExtractedData(receipt.ExtractedData)
        };
    }

    public async Task<Transaction> ConfirmAsync(
        Guid userId,
        Guid receiptId,
        ConfirmReceiptRequest request,
        CancellationToken ct = default)
    {
        var receipt = await _receipts.GetByIdAsync(receiptId, ct)
            ?? throw new KeyNotFoundException($"Receipt {receiptId} not found");
        EnsureReceiptOwner(receipt, userId);

        var transaction = await _transactions.CreateAsync(
            userId,
            new CreateTransactionDto
            {
                Type = TransactionType.Expense,
                Amount = request.Amount,
                CurrencyCode = request.CurrencyCode.Trim().ToUpperInvariant(),
                Category = request.Category,
                Counterparty = request.Merchant,
                Date = request.Date,
                Scope = RecordScope.Personal
            },
            ct);

        receipt.TransactionId = transaction.Id;
        receipt.Status = ReceiptStatus.Confirmed;
        receipt.NeedsReview = false;
        receipt.ExtractedData = SerializeConfirmedData(request, receipt.ExtractedData);
        await _receipts.UpdateAsync(receipt, ct);

        return transaction;
    }

    private static void EnsureReceiptOwner(Receipt receipt, Guid userId)
    {
        if (receipt.UserId != userId)
            throw new UnauthorizedAccessException("Receipt does not belong to the current user.");
    }

    private static string SerializeExtractedData(
        ReceiptScanResultDto parsed,
        decimal total,
        string? currencyCode) =>
        JsonSerializer.Serialize(new
        {
            merchant = parsed.Merchant,
            total,
            currencyCode,
            category = (string?)null,
            date = parsed.Date,
            items = (parsed.LineItems ?? new List<LineItemDto>())
                .Select(item => new
                {
                    name = item.Description,
                    amount = item.Amount
                })
        });

    private static object? ParseExtractedData(string? extractedData)
    {
        if (string.IsNullOrWhiteSpace(extractedData))
            return null;

        return JsonSerializer.Deserialize<JsonElement>(extractedData);
    }

    private static string SerializeConfirmedData(
        ConfirmReceiptRequest request,
        string? previousExtractedData)
    {
        var items = Enumerable.Empty<object>();
        if (!string.IsNullOrWhiteSpace(previousExtractedData))
        {
            using var document = JsonDocument.Parse(previousExtractedData);
            if (document.RootElement.TryGetProperty("items", out var previousItems) &&
                previousItems.ValueKind == JsonValueKind.Array)
            {
                items = previousItems.EnumerateArray()
                    .Select(item => JsonSerializer.Deserialize<object>(item.GetRawText())!)
                    .ToList();
            }
        }

        return JsonSerializer.Serialize(new
        {
            merchant = request.Merchant,
            total = request.Amount,
            currencyCode = request.CurrencyCode.Trim().ToUpperInvariant(),
            category = request.Category,
            date = request.Date,
            items
        });
    }

    private static string ExtensionFor(string contentType) =>
        contentType.ToLowerInvariant() switch
        {
            "image/png" => ".png",
            "image/webp" => ".webp",
            "image/heic" => ".heic",
            "image/heif" => ".heif",
            _ => ".jpg"
        };
}
