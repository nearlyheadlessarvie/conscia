using Conscia.Domain.Enums;
using Conscia.Domain.ValueObjects;

namespace Conscia.Domain.Entities;

public class Transaction
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public TransactionType Type { get; set; }
    public Money Amount { get; set; } = null!;
    public string Category { get; set; } = string.Empty;
    public string? Counterparty { get; set; }
    public DateTime Date { get; set; }
    public Location? Location { get; set; }
    public RegretLevel? RegretLevel { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

public class Location
{
    public double Latitude { get; set; }
    public double Longitude { get; set; }
    public string? PlaceName { get; set; }
}
