using Amazon.CDK;
using Amazon.CDK.AWS.DynamoDB;
using Amazon.CDK.AWS.Events;
using Amazon.CDK.AWS.Events.Targets;
using Amazon.CDK.AWS.Lambda;
using Constructs;

namespace Conscia.Infra;

public class PatternAggregatorStackProps : StackProps
{
    public required ITable ControlPlaneTable { get; set; }
    public required ITable TransactionsTable { get; set; }
    public required ITable WeeklyInsightsTable { get; set; }
    public required ITable PurchasePatternsTable { get; set; }
    public required ITable MonthlyCategorySpendsTable { get; set; }
    public string? AssetPath { get; set; }
}

public class PatternAggregatorStack : Stack
{
    public PatternAggregatorStack(Construct scope, string id, PatternAggregatorStackProps props)
        : base(scope, id, props)
    {
        var assetPath = props.AssetPath
            ?? AssetPathResolver.ResolvePublishedAsset("../publish/pattern-aggregator", "pattern-aggregator");

        var lambda = new Function(this, "PatternAggregatorLambda", new FunctionProps
        {
            FunctionName = "conscia-pattern-aggregator",
            Runtime = Runtime.DOTNET_8,
            Handler = "Conscia.PatternAggregator",
            Code = Code.FromAsset(assetPath),
            MemorySize = 512,
            Timeout = Duration.Minutes(5),
            Architecture = Architecture.ARM_64,
            Tracing = Tracing.ACTIVE,
            Environment = new Dictionary<string, string>
            {
                ["AWS__DynamoDB__ControlPlaneTable"] = props.ControlPlaneTable.TableName,
                ["AWS__DynamoDB__TransactionsTable"] = props.TransactionsTable.TableName,
                ["AWS__DynamoDB__WeeklyInsightsTable"] = props.WeeklyInsightsTable.TableName,
                ["AWS__DynamoDB__PurchasePatternsTable"] = props.PurchasePatternsTable.TableName,
                ["AWS__DynamoDB__MonthlyCategorySpendsTable"] = props.MonthlyCategorySpendsTable.TableName
            }
        });

        props.ControlPlaneTable.GrantReadData(lambda);
        props.TransactionsTable.GrantReadData(lambda);
        props.WeeklyInsightsTable.GrantReadWriteData(lambda);
        props.PurchasePatternsTable.GrantReadWriteData(lambda);
        props.MonthlyCategorySpendsTable.GrantReadData(lambda);

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
