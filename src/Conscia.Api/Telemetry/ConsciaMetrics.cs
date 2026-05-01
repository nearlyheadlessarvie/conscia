using System.Diagnostics.Metrics;

namespace Conscia.Api.Telemetry;

public static class ConsciaMetrics
{
    private static readonly Meter Meter = new("Conscia.Api", "1.0.0");

    public static readonly Counter<long> TransactionsCreated =
        Meter.CreateCounter<long>("conscia.transactions.created");

    public static readonly Counter<long> AIRequestsTotal =
        Meter.CreateCounter<long>("conscia.ai.requests.total");

    public static readonly Counter<long> AIRequestsFailed =
        Meter.CreateCounter<long>("conscia.ai.requests.failed");

    public static readonly Histogram<double> AIResponseDuration =
        Meter.CreateHistogram<double>("conscia.ai.response.duration.ms");

    public static readonly Counter<long> BudgetWarningsTriggered =
        Meter.CreateCounter<long>("conscia.budgets.warnings.triggered");

    public static readonly Counter<long> RegretFeedbackSubmitted =
        Meter.CreateCounter<long>("conscia.regret.feedback.submitted");

    public static readonly Counter<long> ReceiptScansTotal =
        Meter.CreateCounter<long>("conscia.receipts.scans.total");
}
