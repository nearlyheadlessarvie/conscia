namespace Conscia.Domain.Entities;

public class PurchasePatternSummary
{
    public Guid UserId { get; set; }
    public decimal RegrettedAmount { get; set; }
    public string RegrettedCategory { get; set; } = string.Empty;
    public double AvgRegretRate { get; set; }
    public int PatternCount { get; set; }
    public DateTime UpdatedAt { get; set; }
}

public class CategoryPattern
{
    public Guid UserId { get; set; }
    public string Category { get; set; } = string.Empty;
    public decimal TotalSpend { get; set; }
    public decimal RegrettedSpend { get; set; }
    public double RegretRate { get; set; }
    public int TransactionCount { get; set; }
    public decimal ProjectedAnnual { get; set; }
    public DateTime UpdatedAt { get; set; }
}

public class MerchantPattern
{
    public Guid UserId { get; set; }
    public string Merchant { get; set; } = string.Empty;
    public int VisitCount { get; set; }
    public int RegretCount { get; set; }
    public double RegretRate { get; set; }
    public string LastVisitDate { get; set; } = string.Empty;
    public DateTime UpdatedAt { get; set; }
}
