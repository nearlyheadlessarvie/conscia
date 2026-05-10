using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.Model;
using Conscia.Application.Interfaces;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Microsoft.Extensions.Logging;
using System.Linq;

namespace Conscia.PatternAggregator;

public class PatternAggregatorService
{
    private readonly IAmazonDynamoDB _dynamo;
    private readonly IPurchasePatternRepository _patternRepo;
    private readonly IBehavioralInsightsService _insightsService;
    private readonly ILogger<PatternAggregatorService> _logger;

    public PatternAggregatorService(
        IAmazonDynamoDB dynamo,
        IPurchasePatternRepository patternRepo,
        IBehavioralInsightsService insightsService,
        ILogger<PatternAggregatorService> logger)
    {
        _dynamo = dynamo;
        _patternRepo = patternRepo;
        _insightsService = insightsService;
        _logger = logger;
    }

    public async Task RunAsync(CancellationToken ct = default)
    {
        var userIds = await GetActiveUserIdsAsync(ct);
        _logger.LogInformation("Processing {Count} active users", userIds.Count);

        foreach (var userId in userIds)
        {
            try
            {
                await ProcessUserAsync(userId, ct);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to process user {UserId}", userId);
            }
        }
    }

    private async Task ProcessUserAsync(Guid userId, CancellationToken ct)
    {
        var to = DateTime.UtcNow;
        var from = to.AddDays(-30);

        // --- PurchasePatterns aggregation ---
        var transactions = await GetTransactionsForUserAsync(userId, from, to, ct);
        var expenses = transactions
            .Where(t => t.Type == TransactionType.Expense && t.RegretLevel.HasValue)
            .ToList();

        if (expenses.Count > 0)
        {
            var (summary, categories, merchants) = Aggregate(userId, expenses, to);
            await _patternRepo.UpsertManyAsync(userId, summary, categories, merchants, ct);
        }

        // --- WeeklyInsights calculation ---
        var weekStart = GetStartOfWeek(to);
        await _insightsService.CalculateAndStoreWeeklyInsightsAsync(userId, weekStart, ct);

        _logger.LogInformation("Processed user {UserId}: {Expenses} rated expenses", userId, expenses.Count);
    }

    private static (PurchasePatternSummary summary, List<CategoryPattern> categories, List<MerchantPattern> merchants)
        Aggregate(Guid userId, List<Transaction> expenses, DateTime now)
    {
        var categoryGroups = expenses
            .GroupBy(t => t.Category)
            .Select(g =>
            {
                var regretted = g.Where(t => t.RegretLevel != RegretLevel.WorthIt).ToList();
                var totalSpend = g.Sum(t => t.Amount.Amount);
                var regrettedSpend = regretted.Sum(t => t.Amount.Amount);
                var regretRate = (double)regretted.Count / g.Count();
                return new CategoryPattern
                {
                    UserId = userId,
                    Category = g.Key,
                    TotalSpend = totalSpend,
                    RegrettedSpend = regrettedSpend,
                    RegretRate = regretRate,
                    TransactionCount = g.Count(),
                    ProjectedAnnual = regrettedSpend / 30m * 365m,
                    UpdatedAt = now
                };
            }).ToList();

        var merchantGroups = expenses
            .Where(t => !string.IsNullOrWhiteSpace(t.Counterparty))
            .GroupBy(t => t.Counterparty!.Trim(), StringComparer.OrdinalIgnoreCase)
            .Select(g =>
            {
                var regretted = g.Count(t => t.RegretLevel != RegretLevel.WorthIt);
                return new MerchantPattern
                {
                    UserId = userId,
                    Merchant = g.First().Counterparty!.Trim(),
                    VisitCount = g.Count(),
                    RegretCount = regretted,
                    RegretRate = (double)regretted / g.Count(),
                    LastVisitDate = g.Max(t => t.Date).ToString("yyyy-MM-dd"),
                    UpdatedAt = now
                };
            }).ToList();

        var worstCategory = categoryGroups
            .OrderByDescending(c => c.RegrettedSpend)
            .FirstOrDefault();

        var totalRated = expenses.Count;
        var totalRegretted = expenses.Count(t => t.RegretLevel != RegretLevel.WorthIt);

        var summary = new PurchasePatternSummary
        {
            UserId = userId,
            RegrettedAmount = worstCategory?.RegrettedSpend ?? 0m,
            RegrettedCategory = worstCategory?.Category ?? string.Empty,
            AvgRegretRate = totalRated > 0 ? (double)totalRegretted / totalRated : 0.0,
            PatternCount = categoryGroups.Count(c => c.RegretRate >= 0.4),
            UpdatedAt = now
        };

        return (summary, categoryGroups, merchantGroups);
    }

    private async Task<List<Transaction>> GetTransactionsForUserAsync(
        Guid userId, DateTime from, DateTime to, CancellationToken ct)
    {
        var allItems = new List<Transaction>();
        Dictionary<string, AttributeValue>? lastKey = null;

        do
        {
            var request = new QueryRequest
            {
                TableName = "Transactions",
                KeyConditionExpression = "PK = :pk AND SK BETWEEN :from AND :to",
                ExpressionAttributeValues = new Dictionary<string, AttributeValue>
                {
                    [":pk"] = new($"USER#{userId}"),
                    [":from"] = new(DynamoKeys.DateRangeStart(from)),
                    [":to"] = new(DynamoKeys.DateRangeEnd(to))
                },
                ExclusiveStartKey = lastKey
            };

            var response = await _dynamo.QueryAsync(request, ct);
            allItems.AddRange(response.Items.Select(FromItem));
            lastKey = response.LastEvaluatedKey?.Count > 0 ? response.LastEvaluatedKey : null;
        } while (lastKey is not null);

        return allItems;
    }

    private async Task<List<Guid>> GetActiveUserIdsAsync(CancellationToken ct)
    {
        var minDate = DateTime.UtcNow.AddDays(-30).ToString("yyyy-MM-dd");
        var userIds = new HashSet<string>();
        Dictionary<string, AttributeValue>? lastKey = null;

        do
        {
            var request = new ScanRequest
            {
                TableName = "Transactions",
                FilterExpression = "#d >= :minDate",
                ExpressionAttributeNames = new Dictionary<string, string> { ["#d"] = "Date" },
                ExpressionAttributeValues = new Dictionary<string, AttributeValue>
                {
                    [":minDate"] = new(minDate)
                },
                ProjectionExpression = "UserId",
                ExclusiveStartKey = lastKey
            };

            var response = await _dynamo.ScanAsync(request, ct);
            foreach (var item in response.Items)
            {
                if (item.TryGetValue("UserId", out var uid))
                    userIds.Add(uid.S);
            }

            lastKey = response.LastEvaluatedKey?.Count > 0 ? response.LastEvaluatedKey : null;
        } while (lastKey is not null);

        return userIds
            .Where(id => Guid.TryParse(id, out _))
            .Select(Guid.Parse)
            .ToList();
    }

    private static Transaction FromItem(Dictionary<string, AttributeValue> item)
    {
        decimal? exchangeRate = item.TryGetValue("ExchangeRateToBase", out var er) ? decimal.Parse(er.N) : null;
        return new Transaction
        {
            Id = Guid.Parse(item["Id"].S),
            UserId = Guid.Parse(item["UserId"].S),
            Type = Enum.Parse<TransactionType>(item["Type"].S),
            Amount = new Conscia.Domain.ValueObjects.Money(decimal.Parse(item["Amount"].N), item["CurrencyCode"].S, exchangeRate),
            Category = item["Category"].S,
            Counterparty = item.TryGetValue("Counterparty", out var counterparty)
                ? counterparty.S
                : item.TryGetValue("Merchant", out var legacyMerchant)
                    ? legacyMerchant.S
                    : null,
            Date = DateTime.Parse(item["Date"].S),
            RegretLevel = item.TryGetValue("RegretLevel", out var rl) ? Enum.Parse<RegretLevel>(rl.S) : null,
            CreatedAt = DateTime.Parse(item["CreatedAt"].S)
        };
    }

    private static DateTime GetStartOfWeek(DateTime date)
    {
        var diff = (7 + (date.DayOfWeek - DayOfWeek.Monday)) % 7;
        return date.AddDays(-diff).Date;
    }
}
