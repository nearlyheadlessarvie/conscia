using System.Diagnostics;

namespace Conscia.Api.Telemetry;

public static class ConsciaActivitySources
{
    public static readonly ActivitySource AI = new("Conscia.AI");
    public static readonly ActivitySource Transactions = new("Conscia.Transactions");
    public static readonly ActivitySource Budgets = new("Conscia.Budgets");
}
