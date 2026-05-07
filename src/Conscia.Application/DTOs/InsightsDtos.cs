namespace Conscia.Application.DTOs;

public record InsightsSummaryDto(
    decimal RegrettedAmount,
    string RegrettedCategory,
    double AvgRegretRate,
    int PatternCount,
    DateTime UpdatedAt
);

public record CategoryStatDto(
    string Category,
    decimal TotalSpend,
    decimal RegrettedSpend,
    double RegretRate,
    int TransactionCount,
    decimal ProjectedAnnual
);

public record MerchantStatDto(
    string Merchant,
    int VisitCount,
    int RegretCount,
    double RegretRate,
    string LastVisitDate
);

public record TransactionSummaryDto(
    Guid Id,
    decimal Amount,
    string CurrencyCode,
    string Category,
    string? Merchant,
    DateTime Date,
    string? RegretLevel
);

public record CategoryDetailDto(
    CategoryStatDto Stats,
    IReadOnlyList<TransactionSummaryDto> RecentTransactions
);

public record MerchantDetailDto(
    MerchantStatDto Stats,
    IReadOnlyList<TransactionSummaryDto> RecentTransactions
);
