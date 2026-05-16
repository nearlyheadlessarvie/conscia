using Amazon.CDK;
using Amazon.CDK.AWS.Lambda;
using Amazon.CDK.AWS.Logs;
using Constructs;

namespace Conscia.Infra;

public class ObservabilityStackProps : StackProps
{
    public required IFunction ApiLambda { get; set; }
    public required IFunction OutboxLambda { get; set; }
}

public class ObservabilityStack : Stack
{
    public ObservabilityStack(Construct scope, string id, ObservabilityStackProps props)
        : base(scope, id, props)
    {
        CreateLogGroup("ApiLogGroup", props.ApiLambda);
        CreateLogGroup("OutboxLogGroup", props.OutboxLambda);
    }

    private void CreateLogGroup(string id, IFunction lambda)
    {
        new LogGroup(this, id, new LogGroupProps
        {
            LogGroupName = $"/aws/lambda/{lambda.FunctionName}",
            Retention = RetentionDays.ONE_MONTH,
            RemovalPolicy = RemovalPolicy.DESTROY
        });
    }
}
