using System.Text;
using System.Text.Json;
using System.Text.RegularExpressions;
using Amazon.BedrockRuntime;
using Amazon.BedrockRuntime.Model;
using Amazon.Textract;
using Amazon.Textract.Model;
using Conscia.Application.DTOs;
using Conscia.Application.Interfaces;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace Conscia.AI.Services;

public sealed class AwsReceiptOcrService : IOcrService
{
    private const double DeterministicConfidenceThreshold = 0.89;
    private const string UnsupportedReceiptFormatMessage =
        "Receipt file format is not supported. Upload a JPEG, PNG, PDF, or TIFF receipt.";
    private static readonly Regex MoneyRegex = new(
        @"(?:(?<currency>PHP|USD|EUR|GBP|SGD|AUD|CAD)\s*)?(?<symbol>[₱$€£])?\s*(?<amount>\d{1,3}(?:,\d{3})*(?:\.\d{2})|\d+(?:\.\d{2}))",
        RegexOptions.IgnoreCase | RegexOptions.Compiled);

    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true
    };

    private readonly IAmazonTextract _textract;
    private readonly IAmazonBedrockRuntime _bedrock;
    private readonly string _bucketName;
    private readonly BedrockOptions _bedrockOptions;
    private readonly ILogger<AwsReceiptOcrService> _logger;

    public AwsReceiptOcrService(
        IAmazonTextract textract,
        IAmazonBedrockRuntime bedrock,
        IConfiguration configuration,
        IOptions<BedrockOptions> bedrockOptions,
        ILogger<AwsReceiptOcrService> logger)
    {
        _textract = textract;
        _bedrock = bedrock;
        _bucketName = configuration["AWS:S3:BucketName"] ?? string.Empty;
        _bedrockOptions = bedrockOptions.Value;
        _logger = logger;
    }

    public bool IsConfigured =>
        !string.IsNullOrWhiteSpace(_bucketName) &&
        !string.IsNullOrWhiteSpace(_bedrockOptions.ModelId);

    public async Task<string> ExtractTextAsync(string s3Key, CancellationToken ct = default)
    {
        EnsureConfigured();

        DetectDocumentTextResponse response;
        try
        {
            response = await _textract.DetectDocumentTextAsync(
                new DetectDocumentTextRequest
                {
                    Document = new Document
                    {
                        S3Object = new S3Object
                        {
                            Bucket = _bucketName,
                            Name = s3Key
                        }
                    }
                },
                ct);
        }
        catch (UnsupportedDocumentException ex)
        {
            _logger.LogWarning(ex, "Textract rejected unsupported receipt document {S3Key}", s3Key);
            throw new ArgumentException(UnsupportedReceiptFormatMessage, ex);
        }

        var lines = response.Blocks
            .Where(block => block.BlockType == BlockType.LINE)
            .Select(block => block.Text)
            .Where(text => !string.IsNullOrWhiteSpace(text));

        return string.Join("\n", lines);
    }

    public async Task<ReceiptScanResultDto> ParseReceiptTextAsync(
        string rawText,
        CancellationToken ct = default)
    {
        EnsureConfigured();

        var deterministic = ParseDeterministically(rawText);
        if (HasCoreReceiptFields(deterministic) ||
            deterministic.Confidence >= DeterministicConfidenceThreshold)
        {
            return deterministic;
        }

        var requestPayload = JsonSerializer.Serialize(new
        {
            anthropic_version = "bedrock-2023-05-31",
            max_tokens = Math.Max(_bedrockOptions.MaxTokens, 700),
            temperature = 0,
            system = """
            You extract receipt data for a personal finance app.
            Return only one JSON object. Do not wrap it in markdown.
            Use null when a value is missing or uncertain. Never invent currency.
            Schema:
            {
              "merchant": string | null,
              "total": number | null,
              "currencyCode": string | null,
              "date": "YYYY-MM-DD" | null,
              "confidence": number,
              "lineItems": [{"description": string, "amount": number, "quantity": number}]
            }
            """,
            messages = new[]
            {
                new
                {
                    role = "user",
                    content = $"Receipt OCR text:\n{rawText}"
                }
            }
        });

        using var bodyStream = new MemoryStream(Encoding.UTF8.GetBytes(requestPayload));
        var response = await _bedrock.InvokeModelAsync(
            new InvokeModelRequest
            {
                ModelId = _bedrockOptions.ModelId,
                ContentType = "application/json",
                Accept = "application/json",
                Body = bodyStream
            },
            ct);

        using var reader = new StreamReader(response.Body);
        var responseJson = await reader.ReadToEndAsync(ct);
        var modelText = ExtractModelText(responseJson);
        var receiptJson = ExtractJsonObject(modelText);
        var parsed = JsonSerializer.Deserialize<ReceiptParsePayload>(receiptJson, JsonOptions)
            ?? throw new InvalidOperationException("Receipt parser returned empty JSON.");

        return new ReceiptScanResultDto
        {
            Merchant = NormalizeText(parsed.Merchant),
            Total = parsed.Total,
            CurrencyCode = NormalizeCurrency(parsed.CurrencyCode),
            Date = NormalizeDate(parsed.Date),
            Confidence = ClampConfidence(parsed.Confidence),
            LineItems = parsed.LineItems
                .Select(item => new LineItemDto
                {
                    Description = NormalizeText(item.Description) ?? "Item",
                    Amount = item.Amount,
                    Quantity = item.Quantity <= 0 ? 1 : item.Quantity
                })
                .ToList()
        };
    }

    private static ReceiptScanResultDto ParseDeterministically(string rawText)
    {
        var lines = rawText
            .Split('\n', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
            .Where(line => !string.IsNullOrWhiteSpace(line))
            .ToList();

        var merchant = lines.FirstOrDefault(IsLikelyMerchant);
        var total = FindTotal(lines);
        var currencyCode = FindCurrency(lines);
        var date = FindDate(lines);
        var lineItems = FindLineItems(lines);

        var confidence = 0d;
        if (!string.IsNullOrWhiteSpace(merchant)) confidence += 0.25;
        if (total.HasValue && total > 0) confidence += 0.4;
        if (!string.IsNullOrWhiteSpace(currencyCode)) confidence += 0.15;
        if (date.HasValue) confidence += 0.1;
        if (lineItems.Count > 0) confidence += 0.1;

        return new ReceiptScanResultDto
        {
            Merchant = merchant,
            Total = total,
            CurrencyCode = currencyCode,
            Date = date,
            LineItems = lineItems,
            Confidence = Math.Min(confidence, 0.94)
        };
    }

    private static bool HasCoreReceiptFields(ReceiptScanResultDto result) =>
        !string.IsNullOrWhiteSpace(result.Merchant) &&
        result.Total is > 0 &&
        !string.IsNullOrWhiteSpace(result.CurrencyCode);

    private static bool IsLikelyMerchant(string line) =>
        !MoneyRegex.IsMatch(line) &&
        !LooksLikeDate(line) &&
        !line.Contains("total", StringComparison.OrdinalIgnoreCase) &&
        !line.Contains("subtotal", StringComparison.OrdinalIgnoreCase) &&
        line.Any(char.IsLetter);

    private static decimal? FindTotal(IReadOnlyList<string> lines)
    {
        foreach (var line in lines.AsEnumerable().Reverse())
        {
            if (!line.Contains("total", StringComparison.OrdinalIgnoreCase))
                continue;

            var amount = LastAmount(line);
            if (amount.HasValue)
                return amount;
        }

        return null;
    }

    private static string? FindCurrency(IEnumerable<string> lines)
    {
        foreach (var line in lines)
        {
            var match = MoneyRegex.Match(line);
            if (!match.Success)
                continue;

            var explicitCurrency = match.Groups["currency"].Value;
            if (!string.IsNullOrWhiteSpace(explicitCurrency))
                return explicitCurrency.ToUpperInvariant();

            var symbolCurrency = match.Groups["symbol"].Value switch
            {
                "₱" => "PHP",
                "$" => "USD",
                "€" => "EUR",
                "£" => "GBP",
                _ => null
            };

            if (!string.IsNullOrWhiteSpace(symbolCurrency))
                return symbolCurrency;
        }

        return null;
    }

    private static DateTime? FindDate(IEnumerable<string> lines)
    {
        foreach (var line in lines)
        {
            if (DateTime.TryParse(line, out var parsed))
                return DateTime.SpecifyKind(parsed.Date, DateTimeKind.Utc);
        }

        return null;
    }

    private static List<LineItemDto> FindLineItems(IEnumerable<string> lines)
    {
        var items = new List<LineItemDto>();
        foreach (var line in lines)
        {
            if (line.Contains("total", StringComparison.OrdinalIgnoreCase) || LooksLikeDate(line))
                continue;

            var amount = LastAmount(line);
            if (!amount.HasValue)
                continue;

            var description = MoneyRegex.Replace(line, string.Empty).Trim(' ', '-', ':');
            if (string.IsNullOrWhiteSpace(description))
                continue;

            items.Add(new LineItemDto
            {
                Description = description,
                Amount = amount.Value,
                Quantity = 1
            });
        }

        return items;
    }

    private static decimal? LastAmount(string line)
    {
        var matches = MoneyRegex.Matches(line);
        if (matches.Count == 0)
            return null;

        var value = matches[^1].Groups["amount"].Value.Replace(",", string.Empty);
        return decimal.TryParse(value, out var amount) ? amount : null;
    }

    private static bool LooksLikeDate(string line) =>
        DateTime.TryParse(line, out _);

    private void EnsureConfigured()
    {
        if (!IsConfigured)
        {
            _logger.LogError("AWS receipt OCR is not configured.");
            throw new InvalidOperationException("Receipt scanning is not configured.");
        }
    }

    private static string ExtractModelText(string responseJson)
    {
        using var document = JsonDocument.Parse(responseJson);
        return document.RootElement
            .GetProperty("content")[0]
            .GetProperty("text")
            .GetString() ?? "{}";
    }

    private static string ExtractJsonObject(string text)
    {
        var start = text.IndexOf('{');
        var end = text.LastIndexOf('}');
        if (start < 0 || end < start)
        {
            throw new InvalidOperationException("Receipt parser did not return JSON.");
        }

        return text[start..(end + 1)];
    }

    private static string? NormalizeText(string? value)
    {
        var trimmed = value?.Trim();
        return string.IsNullOrWhiteSpace(trimmed) ? null : trimmed;
    }

    private static string? NormalizeCurrency(string? value)
    {
        var trimmed = value?.Trim();
        return string.IsNullOrWhiteSpace(trimmed) ? null : trimmed.ToUpperInvariant();
    }

    private static DateTime? NormalizeDate(string? value)
    {
        if (!DateTime.TryParse(value, out var parsed))
        {
            return null;
        }

        if (parsed.Kind == DateTimeKind.Utc)
        {
            return parsed;
        }

        if (parsed.Kind == DateTimeKind.Local)
        {
            return parsed.ToUniversalTime();
        }

        return DateTime.SpecifyKind(parsed.Date, DateTimeKind.Utc);
    }

    private static double ClampConfidence(double value) =>
        double.IsNaN(value) ? 0 : Math.Clamp(value, 0, 1);

    private sealed class ReceiptParsePayload
    {
        public string? Merchant { get; set; }
        public decimal? Total { get; set; }
        public string? CurrencyCode { get; set; }
        public string? Date { get; set; }
        public double Confidence { get; set; }
        public List<ReceiptParseLineItem> LineItems { get; set; } = [];
    }

    private sealed class ReceiptParseLineItem
    {
        public string? Description { get; set; }
        public decimal Amount { get; set; }
        public int Quantity { get; set; } = 1;
    }
}
