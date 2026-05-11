using Amazon.CDK;
using Amazon.CDK.AWS.APIGateway;
using Amazon.CDK.AWS.Cognito;
using Amazon.CDK.AWS.DynamoDB;
using Amazon.CDK.AWS.IAM;
using Amazon.CDK.AWS.Lambda;
using Amazon.CDK.AWS.S3;
using Amazon.CDK.AWS.SQS;
using Constructs;

namespace Conscia.Infra;

public class ComputeStackProps : StackProps
{
    public required IBucket ReceiptBucket { get; set; }
    public required IUserPool UserPool { get; set; }
    public required IUserPoolClient UserPoolClient { get; set; }
    public required ITable TransactionsTable { get; set; }
    public required ITable AiInteractionsTable { get; set; }
    public required ITable OutboxEventsTable { get; set; }
    public required ITable InAppAlertsTable { get; set; }
    public required ITable WeeklyInsightsTable { get; set; }
    public required ITable PurchasePatternsTable { get; set; }
    public required ITable PushDeviceTokensTable { get; set; }
    public required IQueue AiQueue { get; set; }
    public required IFunction DbAccessLambda { get; set; }
    public string ApiAssetPath { get; set; } = "../publish/api";
}

public class ComputeStack : Stack
{
    public IFunction ApiLambda { get; }

    public ComputeStack(Construct scope, string id, ComputeStackProps props)
        : base(scope, id, props)
    {
        ApiLambda = new Function(this, "ApiLambda", new FunctionProps
        {
            FunctionName = "conscia-api",
            Runtime = Runtime.DOTNET_8,
            Handler = "Conscia.Api",
            Code = Code.FromAsset(props.ApiAssetPath),
            MemorySize = 1024,
            Timeout = Duration.Seconds(30),
            Architecture = Architecture.ARM_64,
            Environment = new Dictionary<string, string>
            {
                ["ASPNETCORE_ENVIRONMENT"] = "Production",
                ["Auth__Cognito__UserPoolId"] = props.UserPool.UserPoolId,
                ["Auth__Cognito__ClientId"] = props.UserPoolClient.UserPoolClientId,
                ["AWS__S3__BucketName"] = props.ReceiptBucket.BucketName,
                ["AWS__SQS__AiQueueUrl"] = props.AiQueue.QueueUrl,
                ["AWS__DynamoDB__TransactionsTable"] = props.TransactionsTable.TableName,
                ["AWS__DynamoDB__AiInteractionsTable"] = props.AiInteractionsTable.TableName,
                ["AWS__DynamoDB__OutboxEventsTable"] = props.OutboxEventsTable.TableName,
                ["AWS__DynamoDB__InAppAlertsTable"] = props.InAppAlertsTable.TableName,
                ["AWS__DynamoDB__WeeklyInsightsTable"] = props.WeeklyInsightsTable.TableName,
                ["AWS__DynamoDB__PurchasePatternsTable"] = props.PurchasePatternsTable.TableName,
                ["AWS__DynamoDB__PushDeviceTokensTable"] = props.PushDeviceTokensTable.TableName,
                ["AWS__Lambda__DbAccessFunctionName"] = props.DbAccessLambda.FunctionName
            },
            Tracing = Tracing.ACTIVE
        });

        var api = new LambdaRestApi(this, "ConsciaApi", new LambdaRestApiProps
        {
            Handler = ApiLambda,
            RestApiName = "conscia-api",
            Proxy = true,
            DeployOptions = new StageOptions
            {
                StageName = "api",
                TracingEnabled = true,
                ThrottlingRateLimit = 100,
                ThrottlingBurstLimit = 200,
                MethodOptions = new Dictionary<string, IMethodDeploymentOptions>
                {
                    ["/api/v1/ai/pre-purchase/POST"] = new MethodDeploymentOptions
                    {
                        ThrottlingRateLimit = 10,
                        ThrottlingBurstLimit = 20
                    },
                    ["/api/v1/ai/reflection/POST"] = new MethodDeploymentOptions
                    {
                        ThrottlingRateLimit = 10,
                        ThrottlingBurstLimit = 20
                    },
                    ["/api/v1/receipts/scan/POST"] = new MethodDeploymentOptions
                    {
                        ThrottlingRateLimit = 5,
                        ThrottlingBurstLimit = 10
                    }
                }
            },
            DefaultCorsPreflightOptions = new CorsOptions
            {
                AllowOrigins = Cors.ALL_ORIGINS,
                AllowMethods = Cors.ALL_METHODS,
                AllowHeaders = ["Authorization", "Content-Type"],
                MaxAge = Duration.Hours(1)
            }
        });

        props.TransactionsTable.GrantReadWriteData(ApiLambda);
        props.AiInteractionsTable.GrantReadWriteData(ApiLambda);
        props.OutboxEventsTable.GrantReadWriteData(ApiLambda);
        props.InAppAlertsTable.GrantReadWriteData(ApiLambda);
        props.WeeklyInsightsTable.GrantReadWriteData(ApiLambda);
        props.PurchasePatternsTable.GrantReadWriteData(ApiLambda);
        props.PushDeviceTokensTable.GrantReadWriteData(ApiLambda);
        props.ReceiptBucket.GrantReadWrite(ApiLambda);
        props.AiQueue.GrantSendMessages(ApiLambda);
        props.DbAccessLambda.GrantInvoke(ApiLambda);

        ApiLambda.AddToRolePolicy(new PolicyStatement(new PolicyStatementProps
        {
            Actions = ["bedrock:InvokeModel"],
            Resources = [$"arn:aws:bedrock:{Region}::foundation-model/anthropic.*"]
        }));

        ApiLambda.AddToRolePolicy(new PolicyStatement(new PolicyStatementProps
        {
            Actions = ["textract:DetectDocumentText"],
            Resources = ["*"]
        }));

        new CfnOutput(this, "ApiUrl", new CfnOutputProps { Value = api.Url });
    }
}
