using Amazon.CDK;
using Amazon.CDK.AWS.DynamoDB;
using Amazon.CDK.AWS.Events;
using Amazon.CDK.AWS.Events.Targets;
using Amazon.CDK.AWS.Lambda;
using Constructs;

namespace Conscia.Infra;

public class RecurringProcessorStackProps : StackProps
{
    public required ITable TransactionsTable { get; set; }
    public required ITable RecurringSchedulesTable { get; set; }
    public required ITable OutboxEventsTable { get; set; }
    public required ITable InAppAlertsTable { get; set; }
    public string? AssetPath { get; set; }
}

public class RecurringProcessorStack : Stack
{
    public IFunction RecurringProcessorLambda { get; }

    public RecurringProcessorStack(Construct scope, string id, RecurringProcessorStackProps props)
        : base(scope, id, props)
    {
        var assetPath = props.AssetPath
            ?? AssetPathResolver.ResolvePublishedAsset("../publish/recurring-processor", "recurring-processor");

        RecurringProcessorLambda = new Function(this, "RecurringProcessorLambda", new FunctionProps
        {
            FunctionName = "conscia-recurring-processor",
            Runtime = Runtime.DOTNET_8,
            Handler = "Conscia.RecurringProcessor",
            Code = Code.FromAsset(assetPath),
            MemorySize = 512,
            Timeout = Duration.Minutes(2),
            Architecture = Architecture.ARM_64,
            Environment = new Dictionary<string, string>
            {
                ["AWS__DynamoDB__TransactionsTable"] = props.TransactionsTable.TableName,
                ["AWS__DynamoDB__RecurringSchedulesTable"] = props.RecurringSchedulesTable.TableName,
                ["AWS__DynamoDB__OutboxEventsTable"] = props.OutboxEventsTable.TableName,
                ["AWS__DynamoDB__InAppAlertsTable"] = props.InAppAlertsTable.TableName
            },
            Tracing = Tracing.ACTIVE
        });

        props.TransactionsTable.GrantReadWriteData(RecurringProcessorLambda);
        props.RecurringSchedulesTable.GrantReadWriteData(RecurringProcessorLambda);
        props.OutboxEventsTable.GrantReadWriteData(RecurringProcessorLambda);
        props.InAppAlertsTable.GrantReadWriteData(RecurringProcessorLambda);

        var rule = new Rule(this, "RecurringProcessorSchedule", new RuleProps
        {
            Schedule = Schedule.Rate(Duration.Minutes(5))
        });

        rule.AddTarget(new LambdaFunction(RecurringProcessorLambda));
    }
}
