namespace Conscia.Domain.Entities;

public class BehaviorProfile
{
    public Guid UserId { get; set; }
    public int PreventedPurchases { get; set; }
    public int Overrides { get; set; }
    public int Regrets { get; set; }
}
