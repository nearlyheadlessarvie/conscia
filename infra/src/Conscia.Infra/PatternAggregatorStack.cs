using Amazon.CDK;
using Amazon.CDK.AWS.DynamoDB;
using Amazon.CDK.AWS.Events;
using Amazon.CDK.AWS.Events.Targets;
using Amazon.CDK.AWS.Lambda;
using Constructs;

namespace Conscia.Infra;

public class PatternAggregatorStackProps : StackProps
{
    public required ITable TransactionsTable { get; set; }
    public required ITable WeeklyInsightsTable { get; set; }
    public required ITable PurchasePatternsTable { get; set; }
}

public class PatternAggregatorStack : Stack
{
    public PatternAggregatorStack(Construct scope, string id, PatternAggregatorStackProps props)
        : base(scope, id, props)
    {
        var lambda = new Function(this, "PatternAggregatorLambda", new FunctionProps
        {
            FunctionName = "conscia-pattern-aggregator",
            Runtime = Runtime.DOTNET_8,
            Handler = "Conscia.PatternAggregator",
            Code = Code.FromAsset("../publish/pattern-aggregator"),
            MemorySize = 512,
            Timeout = Duration.Minutes(5),
            Architecture = Architecture.ARM_64,
            Tracing = Tracing.ACTIVE
        });

        props.TransactionsTable.GrantReadData(lambda);
        props.WeeklyInsightsTable.GrantReadWriteData(lambda);
        props.PurchasePatternsTable.GrantReadWriteData(lambda);

        var rule = new Rule(this, "NightlySchedule", new RuleProps
        {
            Schedule = Schedule.Cron(new CronOptions
            {
                Minute = "0",
                Hour = "2",
                Day = "*",
                Month = "*",
                Year = "*"
            })
        });

        rule.AddTarget(new LambdaFunction(lambda));
    }
}
